import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:success_academy/account/services/account_service.dart'
    as shared_preferences_service;
import 'package:success_academy/account/services/user_service.dart'
    as user_service;
import 'package:success_academy/profile/data/profile_model.dart';
import 'package:success_academy/profile/services/profile_service.dart'
    as profile_service;
import 'package:success_academy/profile/services/purchase_service.dart'
    as stripe_service;

enum AuthStatus {
  signedIn,
  signedOut,
  emailVerification,
  loading,
}

enum UserType {
  student,
  studentNoProfile,
  teacher,
  admin,
}

class AccountModel extends ChangeNotifier {
  AuthStatus _authStatus = AuthStatus.signedOut;
  String _locale = 'en';
  User? _firebaseUser;
  MyUserModel? _myUser;
  StudentProfileModel? _studentProfile;
  TeacherProfileModel? _teacherProfile;
  AdminProfileModel? _adminProfile;
  late List<TeacherProfileModel> _teacherProfileList;
  late Map<String, TeacherProfileModel> _teacherProfileMap;
  List<QueryDocumentSnapshot<Object?>> _subscriptionDocs = [];
  SubscriptionPlan? _subscriptionPlan;
  String? _pointSubscriptionPriceId;
  int? _pointSubscriptionQuantity;

  AccountModel() {
    init();
  }

  AuthStatus get authStatus => _authStatus;
  String get locale => _locale;
  User? get firebaseUser => _firebaseUser;
  MyUserModel? get myUser => _myUser;
  StudentProfileModel? get studentProfile => _studentProfile;
  TeacherProfileModel? get teacherProfile => _teacherProfile;
  AdminProfileModel? get adminProfile => _adminProfile;
  List<TeacherProfileModel> get teacherProfileList => _teacherProfileList;
  Map<String, TeacherProfileModel> get teacherProfileModelMap =>
      _teacherProfileMap;
  SubscriptionPlan? get subscriptionPlan => _subscriptionPlan;
  String? get pointSubscriptionPriceId => _pointSubscriptionPriceId;
  int? get pointSubscriptionQuantity => _pointSubscriptionQuantity;
  UserType get userType {
    if (_adminProfile != null) {
      return UserType.admin;
    }
    if (_teacherProfile != null) {
      return UserType.teacher;
    }
    if (_studentProfile == null) {
      return UserType.studentNoProfile;
    }
    return UserType.student;
  }

  set myUser(MyUserModel? myUser) {
    _myUser = myUser;
    notifyListeners();
  }

  set authStatus(AuthStatus authStatus) {
    _authStatus = authStatus;
    notifyListeners();
  }

  set locale(String locale) {
    _locale = locale;
    notifyListeners();
    shared_preferences_service.updateLocale(locale);
  }

  set pointSubscriptionQuantity(int? pointSubscriptionQuantity) {
    _pointSubscriptionQuantity = pointSubscriptionQuantity;
    notifyListeners();
  }

  set studentProfile(StudentProfileModel? studentProfile) {
    _studentProfile = studentProfile;
    shared_preferences_service.updateStudentProfile(studentProfile);
    _refreshSubscriptionData();
  }

  Future<void> init() async {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      _authStatus = AuthStatus.loading;
      notifyListeners();
      if (firebaseUser != null) {
        try {
          await _initAccount(firebaseUser);
        } catch (err) {
          // TODO: Handle errors and log events
          await FirebaseAnalytics.instance.logEvent(
            name: 'initAccount_failed',
            parameters: {
              'message': err.toString(),
            },
          );
        }
        if (!firebaseUser.emailVerified) {
          if (_authStatus != AuthStatus.emailVerification) {
            // Only send verification email once on initial auth status change
            firebaseUser.sendEmailVerification();
          }
          _authStatus = AuthStatus.emailVerification;
        } else {
          _authStatus = AuthStatus.signedIn;
        }
      } else {
        _signOut();
      }
      notifyListeners();
    });
    _locale = await shared_preferences_service.getLocale();
  }

  /// Initialize account model with firebase user data, data from 'myUsers'
  /// collection, and profile data from shared preferences if existing.
  Future<void> _initAccount(User firebaseUser) async {
    _firebaseUser = firebaseUser;
    _teacherProfileList = await profile_service.getAllTeacherProfiles();
    _teacherProfileMap =
        TeacherProfileModel.buildTeacherProfileMap(_teacherProfileList);
    _subscriptionDocs =
        await stripe_service.getSubscriptionsForUser(firebaseUser.uid);

    await user_service.createMyUserDocIfNotExist(
      firebaseUser.uid,
      firebaseUser.email!,
    );
    _myUser = await user_service.getMyUserDoc(firebaseUser.uid);
    await _initProfile(firebaseUser.uid);
  }

  Future<void> _initProfile(String userId) async {
    final adminProfile = await profile_service.getAdminProfileForUser(userId);
    final teacherProfile =
        await profile_service.getTeacherProfileForUser(userId);
    if (adminProfile != null) {
      // Admin profile
      _adminProfile = adminProfile;
    } else if (teacherProfile != null) {
      // Teacher profile
      _teacherProfile = teacherProfile;
    } else {
      // Student profile
      final studentProfile =
          await shared_preferences_service.loadStudentProfile(userId: userId);
      final studentProfileBelongsToUser =
          await profile_service.studentProfileBelongsToUser(
        userId: userId,
        profileId: studentProfile?.profileId,
      );
      if (studentProfileBelongsToUser) {
        _studentProfile = studentProfile;
        _subscriptionPlan =
            _getSubscriptionTypeForProfile(studentProfile!.profileId);
        _pointSubscriptionPriceId =
            _getPointSubscriptionPriceId(studentProfile.profileId);
        _pointSubscriptionQuantity =
            _getPointSubscriptionQuantity(studentProfile.profileId);
      }
    }
  }

  void _signOut() {
    _authStatus = AuthStatus.signedOut;
    _firebaseUser = null;
    _studentProfile = null;
    _teacherProfile = null;
    _adminProfile = null;
    shared_preferences_service.removeStudentProfile();
  }

  SubscriptionPlan? _getSubscriptionTypeForProfile(String? profileId) {
    if (profileId == null) {
      return null;
    }
    try {
      return _subscriptionDocs
          .where(
            (doc) =>
                doc.get('metadata.profile_id') as String == profileId &&
                SubscriptionPlan.values
                    .map((value) => value.name)
                    .contains(doc.get('items')[0]['price']['metadata']['id']),
          )
          .map(
            (doc) => EnumToString.fromString(
              SubscriptionPlan.values,
              doc['items'][0]['price']['metadata']['id'],
            ),
          )
          .single;
    } on StateError {
      debugPrint(
        'getSubscriptionTypeForProfile: No subscription found for profile $profileId',
      );
      FirebaseAnalytics.instance.logEvent(
        name: 'getSubscriptionTypeForProfile',
        parameters: {
          'message': 'No subscription found for profile $profileId',
        },
      );
      return null;
    }
  }

  String? _getPointSubscriptionPriceId(String? profileId) {
    if (profileId == null) {
      return null;
    }
    try {
      return _subscriptionDocs.firstWhere(
        (doc) =>
            doc.get('metadata.profile_id') as String == profileId &&
            (doc['items'][0]['price']['metadata']['id'] as String)
                .contains('point'),
      )['items'][0]['price']['id'];
    } on StateError {
      return null;
    }
  }

  int? _getPointSubscriptionQuantity(String? profileId) {
    if (profileId == null) {
      return null;
    }
    try {
      return _subscriptionDocs.firstWhere(
        (doc) =>
            doc.get('metadata.profile_id') as String == profileId &&
            (doc['items'][0]['price']['metadata']['id'] as String)
                .contains('point'),
      )['items'][0]['quantity'];
    } on StateError {
      return null;
    }
  }

  Future<void> _refreshSubscriptionData() async {
    _subscriptionDocs =
        await stripe_service.getSubscriptionsForUser(_firebaseUser!.uid);
    _subscriptionPlan =
        _getSubscriptionTypeForProfile(studentProfile?.profileId);
    _pointSubscriptionPriceId =
        _getPointSubscriptionPriceId(studentProfile?.profileId);
    _pointSubscriptionQuantity =
        _getPointSubscriptionQuantity(studentProfile?.profileId);
    notifyListeners();
  }

  bool shouldShowContent() =>
      userType != UserType.student || _subscriptionPlan != null;

  bool hasPointsDiscount() =>
      _subscriptionPlan == SubscriptionPlan.minimum ||
      _subscriptionPlan == SubscriptionPlan.minimumPreschool;
}

class MyUserModel {
  final String referralCode;
  final String email;
  String timeZone;

  MyUserModel({
    required this.referralCode,
    required this.email,
    required this.timeZone,
  });

  MyUserModel.fromJson(Map<String, Object?> json)
      : referralCode = json['referral_code'] as String,
        email = json['email'] as String,
        timeZone = json['time_zone'] as String;

  Map<String, Object?> toJson() => {
        'referral_code': referralCode,
        'email': email,
        'time_zone': timeZone,
      };
}
