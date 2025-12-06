import 'package:cloud_firestore/cloud_firestore.dart';

enum PointTransactionType {
  purchase,
}

class PointTransactionModel {
  final Timestamp timestamp;
  final PointTransactionType type;
  final int amount;
  final int totalAmount;

  PointTransactionModel({
    required this.type,
    required this.amount,
    required this.totalAmount,
  }) : timestamp = Timestamp.now();

  PointTransactionModel.fromFirestore(Map<String, dynamic> json)
      : timestamp = json['timestamp'],
        type = PointTransactionType.values
            .firstWhere((type) => type.name == json['type']),
        amount = json['amount'],
        totalAmount = json['total_amount'];

  Map<String, Object?> toFirestore() => {
        'timestamp': timestamp,
        'type': type.name,
        'amount': amount,
        'total_amount': totalAmount,
      };
}
