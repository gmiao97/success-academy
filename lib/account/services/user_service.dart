import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:random_string/random_string.dart';
import 'package:success_academy/account/data/account_model.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;

final CollectionReference<MyUserModel> _myUserModelRef =
    _db.collection('myUsers').withConverter<MyUserModel>(
          fromFirestore: (doc, _) => MyUserModel.fromJson(doc.data()!),
          toFirestore: (myUserModel, _) => myUserModel.toJson(),
        );

/// Create document in 'myUsers' collection for user uid if not already existing
Future<void> createMyUserDocIfNotExist(String userId, String email) async {
  final userDoc = await _myUserModelRef.doc(userId).get();
  if (!userDoc.exists) {
    final localTimeZone = await FlutterNativeTimezone.getLocalTimezone();
    await _myUserModelRef.doc(userId).set(
          MyUserModel(
            referralCode: randomAlphaNumeric(8),
            timeZone: localTimeZone,
            email: email,
          ),
        );
  }
}

/// Get specified MyUser instance
Future<MyUserModel?> getMyUserDoc(String userId) async {
  final userDoc = await _myUserModelRef.doc(userId).get();
  return userDoc.data();
}

Future<void> updateMyUser({required String userId, String? timeZone}) {
  if (timeZone == null) {
    return Future.value();
  }
  return _myUserModelRef.doc(userId).update({'time_zone': timeZone});
}

Future<List<String>> getReferralCodes() async {
  final myUsers = await _myUserModelRef.get();
  return myUsers.docs.map((doc) => doc.get('referral_code') as String).toList();
}
