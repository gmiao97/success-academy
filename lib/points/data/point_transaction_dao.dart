import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:success_academy/points/data/point_transaction_model.dart';

class PointTransactionDao {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<PointTransactionModel> _pointTransactionsRef(
    String userId,
    String studentProfileId,
  ) =>
      _db
          .collection('myUsers')
          .doc(userId)
          .collection('student_profiles')
          .doc(studentProfileId)
          .collection('point_transactions')
          .withConverter(
            fromFirestore: (doc, _) =>
                PointTransactionModel.fromFirestore(doc.data()!),
            toFirestore: (model, _) => model.toFirestore(),
          );

  Future<void> add({
    required String userId,
    required String studentProfileId,
    required PointTransactionModel model,
  }) =>
      _pointTransactionsRef(userId, studentProfileId).add(model);

  Future<List<PointTransactionModel>> list({
    required String userId,
    required String studentProfileId,
  }) async =>
      (await _pointTransactionsRef(userId, studentProfileId).get())
          .docs
          .map(
            (doc) => doc.data(),
          )
          .sortedBy((data) => data.timestamp)
          .toList();
}
