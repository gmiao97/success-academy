import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:success_academy/lesson_info/data/lesson_model.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;

CollectionReference<LessonModel> _lessonModelRef =
    _db.collection('lessons').withConverter<LessonModel>(
          fromFirestore: (doc, _) => LessonModel.fromJson(doc.data()!),
          toFirestore: (profileModel, _) => profileModel.toJson(),
        );

/// Get list of all lesson information.
Future<List<LessonModel>> getLessons({required bool includePreschool}) async {
  final result = await (includePreschool
      ? _lessonModelRef.get()
      : _lessonModelRef.where('visibility', isNotEqualTo: 'preschool').get());
  return result.docs
      .map(
        (e) => e.data(),
      )
      .toList();
}

/// Update given lesson.
Future<void> updateLesson(String id, LessonModel data) =>
    _db.collection('lessons').doc(id).update(data.toJson());
