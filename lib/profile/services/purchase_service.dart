import 'dart:async';
import 'dart:html' as html;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:success_academy/profile/data/profile_model.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;

Future<List<QueryDocumentSnapshot>> getSubscriptionsForUser(
  String userId,
) async {
  final subscriptionsQuery = await _db
      .collection('customers')
      .doc(userId)
      .collection('subscriptions')
      .where('status', whereIn: ['trialing', 'active']).get();
  return subscriptionsQuery.docs;
}

Future<List<QueryDocumentSnapshot>> _getAllPrices() async {
  final pricesQuery = await _db.collectionGroup('prices').get();
  return pricesQuery.docs.where((doc) => doc.get('active') == true).toList();
}

Future<void> startStripeSubscriptionCheckoutSession({
  required String userId,
  required String profileId,
  required SubscriptionPlan subscriptionPlan,
  required String? referralType,
}) async {
  String? selectedPriceId;
  final priceDocs = await _getAllPrices();
  for (final doc in priceDocs) {
    try {
      if (doc.get('metadata.id') ==
          EnumToString.convertToString(subscriptionPlan)) {
        selectedPriceId = doc.id;
      }
    } on StateError {
      debugPrint('No metadata.id field found for price ${doc.id}');
    }
  }
  final completer = Completer();
  final lineItems = [
    {
      'price': selectedPriceId,
      'quantity': 1,
    },
  ];

  final checkoutSessionDoc = await _db
      .collection('customers')
      .doc(userId)
      .collection('checkout_sessions')
      .add(
    {
      'line_items': lineItems,
      'trial_period_days': 14,
      'success_url': html.window.location.origin,
      'cancel_url': html.window.location.origin,
      'metadata': {
        'profile_id': profileId,
        'referral_type': referralType ?? 'none',
      },
    },
  );
  checkoutSessionDoc.snapshots().listen(
    (doc) {
      if (doc.data()!.containsKey('url')) {
        html.window.location.replace(doc.data()!['url']);
        completer.complete();
      }
      if (doc.data()!.containsKey('error')) {
        completer.completeError(Exception(doc.data()!['error']['message']));
      }
    },
  );
  return completer.future;
}

Future<void> startStripePointsCheckoutSession({
  required String userId,
  required String profileId,
  required int quantity,
  required String? coupon,
}) async {
  String? selectedPriceId;
  final priceDocs = await _getAllPrices();
  for (final doc in priceDocs) {
    try {
      if (doc.get('metadata.id') == 'point') {
        selectedPriceId = doc.id;
      }
    } on StateError {
      debugPrint('No metadata.id field found for price ${doc.id}');
    }
  }

  final data = {
    'mode': 'payment',
    'price': selectedPriceId,
    'quantity': quantity,
    'success_url': html.window.location.origin,
    'cancel_url': html.window.location.origin,
    'metadata': {
      'userId': userId,
      'profileId': profileId,
      'priceId': selectedPriceId,
      'numPoints': quantity,
    },
  };
  if (coupon != null) {
    data['promotion_code'] = coupon;
  }

  final checkoutSessionDoc = await _db
      .collection('customers')
      .doc(userId)
      .collection('checkout_sessions')
      .add(data);
  final completer = Completer();
  checkoutSessionDoc.snapshots().listen(
    (doc) {
      if (doc.data()!.containsKey('url')) {
        html.window.location.replace(doc.data()!['url']);
        completer.complete();
      }
      if (doc.data()!.containsKey('error')) {
        completer.completeError(Exception(doc.data()!['error']['message']));
      }
    },
  );
  return completer.future;
}

Future<void> redirectToStripePortal() async {
  final getStripePortalCallable =
      FirebaseFunctions.instanceFor(region: 'us-west2')
          .httpsCallable('ext-firestore-stripe-payments-createPortalLink');
  try {
    final data = await getStripePortalCallable
        .call(<String, dynamic>{'returnUrl': html.window.location.origin});
    html.window.location.assign(data.data['url']);
  } catch (err) {
    debugPrint('redirectToStripePortal failed: $err');
    throw HttpException('redirectToStripePortal failed: $err');
  }
}

Future<void> startStripePointSubscriptionCheckoutSession({
  required String userId,
  required String profileId,
  required String priceId,
  required int quantity,
}) async {
  final completer = Completer();
  final lineItems = [
    {
      'price': priceId,
      'quantity': quantity,
    },
  ];

  final checkoutSessionDoc = await _db
      .collection('customers')
      .doc(userId)
      .collection('checkout_sessions')
      .add(
    {
      'line_items': lineItems,
      'success_url': html.window.location.origin,
      'cancel_url': html.window.location.origin,
      'metadata': {
        'profile_id': profileId,
      },
    },
  );
  checkoutSessionDoc.snapshots().listen(
    (doc) {
      if (doc.data()!.containsKey('url')) {
        html.window.location.replace(doc.data()!['url']);
        completer.complete();
      }
      if (doc.data()!.containsKey('error')) {
        completer.completeError(Exception(doc.data()!['error']['message']));
      }
    },
  );
  return completer.future;
}
