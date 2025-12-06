import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:success_academy/profile/data/profile_model.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;

CollectionReference<StudentProfileModel> _studentProfileModelRefForUser(
  userId,
) =>
    _db
        .collection('myUsers')
        .doc(userId)
        .collection('student_profiles')
        .withConverter<StudentProfileModel>(
          fromFirestore: (doc, _) => StudentProfileModel.fromFirestoreJson(
            doc.id,
            doc.data()!,
          ),
          toFirestore: (profileModel, _) => profileModel.toFirestoreJson(),
        );

CollectionReference<TeacherProfileModel> _teacherProfileModelRefForUser(
  userId,
) =>
    _db
        .collection('myUsers')
        .doc(userId)
        .collection('teacher_profile')
        .withConverter<TeacherProfileModel>(
          fromFirestore: (doc, _) =>
              TeacherProfileModel.fromJson(doc.id, doc.data()!),
          toFirestore: (teacherProfileModel, _) => teacherProfileModel.toJson(),
        );

CollectionReference<AdminProfileModel> _adminProfileModelRefForUser(userId) =>
    _db
        .collection('myUsers')
        .doc(userId)
        .collection('admin_profile')
        .withConverter<AdminProfileModel>(
          fromFirestore: (doc, _) =>
              AdminProfileModel.fromJson(doc.id, doc.data()!),
          toFirestore: (adminProfileModel, _) => adminProfileModel.toJson(),
        );

/// Get list of all student profiles of the user
Future<List<StudentProfileModel>> getStudentProfilesForUser(
  String userId,
) async =>
    (await _studentProfileModelRefForUser(userId).get())
        .docs
        .map((doc) => doc.data())
        .toList();

/// Get teacher profile under the user
///
/// There should only be a single teacher profile under a user.
Future<TeacherProfileModel?> getTeacherProfileForUser(String userId) async {
  final result = await _teacherProfileModelRefForUser(userId).limit(1).get();
  return result.size > 0 ? result.docs[0].data() : null;
}

/// Get admin profile under the user
///
/// There should only be a single admin profile under a user.
Future<AdminProfileModel?> getAdminProfileForUser(String userId) async {
  final result = await _adminProfileModelRefForUser(userId).limit(1).get();
  return result.size > 0 ? result.docs[0].data() : null;
}

/// Get all teacher profiles
Future<List<TeacherProfileModel>> getAllTeacherProfiles() async => (await _db
        .collectionGroup('teacher_profile')
        .withConverter<TeacherProfileModel>(
          fromFirestore: (doc, _) =>
              TeacherProfileModel.fromJson(doc.id, doc.data()!),
          toFirestore: (teacherProfileModel, _) => teacherProfileModel.toJson(),
        )
        .get())
    .docs
    .map(((e) => e.data()))
    .toList();

/// Get all student profiles
Future<List<StudentProfileModel>> getStudentProfiles(
  List<String> studentProfileIds,
) async {
  if (studentProfileIds.isEmpty) {
    return [];
  }

  final result = await _db
      .collectionGroup('student_profiles')
      .where('id', whereIn: studentProfileIds)
      .withConverter<StudentProfileModel>(
        fromFirestore: (doc, _) => StudentProfileModel.fromFirestoreJson(
          doc.id,
          doc.data()!,
        ),
        toFirestore: (profileModel, _) => profileModel.toFirestoreJson(),
      )
      .get();
  return result.docs.map(((e) => e.data())).toList();
}

/// Get all student profiles
Future<List<StudentProfileModel>> getAllStudentProfiles() async {
  final result = await _db
      .collectionGroup('student_profiles')
      .withConverter<StudentProfileModel>(
        fromFirestore: (doc, _) => StudentProfileModel.fromFirestoreJson(
          doc.id,
          doc.data()!,
        ),
        toFirestore: (profileModel, _) => profileModel.toFirestoreJson(),
      )
      .get();
  return result.docs.map(((e) => e.data())).toList();
}

/// Check if saved profile in local storage belongs to user
Future<bool> studentProfileBelongsToUser({
  required String userId,
  required String? profileId,
}) async {
  if (profileId == null) {
    return false;
  }
  return (await getStudentProfilesForUser(userId))
      .any((p) => p.profileId == profileId);
}

/// Get number of points for student profile
Future<int> getNumberPoints({
  required String userId,
  required String profileId,
}) async =>
    (await _studentProfileModelRefForUser(userId).doc(profileId).get())
        .data()!
        .numPoints;

/// Add student profile for specified user
Future<DocumentReference<StudentProfileModel>> addStudentProfile(
  String userId,
  StudentProfileModel profileModel,
) async {
  final profileDoc =
      await _studentProfileModelRefForUser(userId).add(profileModel);
  await profileDoc.update({'id': profileDoc.id});
  return profileDoc;
}

/// Update student profile for specified user
Future<void> updateStudentProfile(
  String userId,
  StudentProfileModel profileModel,
) =>
    _studentProfileModelRefForUser(userId)
        .doc(profileModel.profileId)
        .update(profileModel.toFirestoreJson());
