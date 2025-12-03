import 'package:flutter/material.dart';
import 'package:success_academy/constants.dart' as constants;
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/profile/services/profile_service.dart'
    as profile_service;

// Corresponds to metadata field 'id' in price in Stripe dashboard
enum SubscriptionPlan { minimum, minimumPreschool, monthly }

String getSubscriptionPlanName(BuildContext context, SubscriptionPlan? plan) {
  switch (plan) {
    case SubscriptionPlan.minimum:
      return S.of(context).minimumCourse;
    case SubscriptionPlan.minimumPreschool:
      return S.of(context).minimumPreschoolCourse;
    case SubscriptionPlan.monthly:
      return S.of(context).monthlyCourse;
    default:
      return S.of(context).noPlan;
  }
}

class StudentProfileModel {
  String _profileId = '';
  String email = '';
  late String lastName;
  late String firstName;
  late DateTime dateOfBirth;
  int numPoints;
  String? referrer;

  StudentProfileModel() : numPoints = 0;

  StudentProfileModel.fromFirestoreJson(
    String profileId,
    Map<String, Object?> json,
  )   : _profileId = profileId,
        email = json['email'] as String,
        lastName = json['last_name'] as String,
        firstName = json['first_name'] as String,
        dateOfBirth = DateTime.parse(json['date_of_birth'] as String),
        numPoints = json['num_points'] as int,
        referrer = json['referrer'] as String?;

  /// Used to read profile from shared preferences.
  StudentProfileModel._fromJson(
    Map<String, Object?> json, {
    required String userId,
  })  : _profileId = json['id'] as String,
        email = json['email'] as String,
        lastName = json['last_name'] as String,
        firstName = json['first_name'] as String,
        dateOfBirth = DateTime.parse(json['date_of_birth'] as String),
        numPoints = json['num_points'] as int,
        referrer = json['referrer'] as String?;

  static Future<StudentProfileModel> create(
    Map<String, Object?> json, {
    required String userId,
  }) async {
    final profile = StudentProfileModel._fromJson(json, userId: userId)
      ..numPoints = await profile_service.getNumberPoints(
        userId: userId,
        profileId: json['id'] as String,
      );
    return profile;
  }

  String get profileId => _profileId;

  Map<String, Object?> toFirestoreJson() => {
        'id': _profileId,
        'email': email,
        'last_name': lastName,
        'first_name': firstName,
        'date_of_birth': constants.dateFormatter.format(dateOfBirth),
        'num_points': numPoints,
        'referrer': referrer,
      };

  /// Used to write profile to shared preferences.
  Map<String, Object?> toJson() => {
        'id': _profileId,
        'email': email,
        'last_name': lastName,
        'first_name': firstName,
        'date_of_birth': constants.dateFormatter.format(dateOfBirth),
        'num_points': numPoints,
        'referrer': referrer,
      };
}

class TeacherProfileModel {
  final String _profileId;
  final String _email;
  final String _lastName;
  final String _firstName;

  TeacherProfileModel.fromJson(String profileId, Map<String, Object?> json)
      : _profileId = profileId,
        _email = json['email'] as String,
        _lastName = json['last_name'] as String,
        _firstName = json['first_name'] as String;

  String get profileId => _profileId;
  String get email => _email;
  String get lastName => _lastName;
  String get firstName => _firstName;

  Map<String, Object?> toJson() => {
        'email': _email,
        'last_name': _lastName,
        'first_name': _firstName,
      };

  static Map<String, TeacherProfileModel> buildTeacherProfileMap(
    List<TeacherProfileModel> teacherProfiles,
  ) {
    final map = Map<String, TeacherProfileModel>.fromIterable(
      teacherProfiles,
      key: (profile) => profile._profileId,
    );
    return map;
  }
}

class AdminProfileModel {
  final String _profileId;
  final String _email;
  final String _lastName;
  final String _firstName;

  AdminProfileModel.fromJson(String profileId, Map<String, Object?> json)
      : _profileId = profileId,
        _email = json['email'] as String,
        _lastName = json['last_name'] as String,
        _firstName = json['first_name'] as String;

  String get profileId => _profileId;
  String get email => _email;
  String get lastName => _lastName;
  String get firstName => _firstName;

  Map<String, Object?> toJson() => {
        'email': _email,
        'last_name': _lastName,
        'first_name': _firstName,
      };
}
