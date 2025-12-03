import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;

Future<List<String>> getFreeReferralCodes() async {
  final freeReferralCodes = await _db.collectionGroup('free').get();
  return freeReferralCodes.docs
      .map((doc) => doc.data()['code'] as String)
      .toList();
}

Future<List<String>> getFiftyOffReferralCodes() async {
  final fiftyOffReferralCodes = await _db.collectionGroup('fifty').get();
  return fiftyOffReferralCodes.docs
      .map((doc) => doc.data()['code'] as String)
      .toList();
}

Future<List<String>> getTwentyOffReferralCodes() async {
  final twentyOffReferralCodes = await _db.collectionGroup('twenty').get();
  return twentyOffReferralCodes.docs
      .map((doc) => doc.data()['code'] as String)
      .toList();
}
