import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/account/services/referral_code_service.dart'
    as referral_code_service;
import 'package:success_academy/constants.dart' as constants;
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/helpers/subscription.dart';
import 'package:success_academy/profile/data/profile_model.dart';
import 'package:success_academy/profile/services/purchase_service.dart'
    as stripe_service;

class CreateSubscriptionForm extends StatefulWidget {
  final SubscriptionPlan subscriptionPlan;
  final Function(SubscriptionPlan?) onSubscriptionPlanChange;
  final bool redirectClicked;
  final ValueSetter<String?> setReferralType;
  final ValueSetter<String?> setReferrer;
  final VoidCallback onStripeSubmitClicked;

  const CreateSubscriptionForm({
    super.key,
    required this.subscriptionPlan,
    required this.onSubscriptionPlanChange,
    required this.redirectClicked,
    required this.setReferralType,
    required this.setReferrer,
    required this.onStripeSubmitClicked,
  });

  @override
  State<CreateSubscriptionForm> createState() => _CreateSubscriptionFormState();
}

class _CreateSubscriptionFormState extends State<CreateSubscriptionForm> {
  final List<String> _freeReferralCodes = [];
  final List<String> _fiftyOffReferralCodes = [];
  final List<String> _twentyOffReferralCodes = [];
  String? _referralType;
  bool _invalidReferral = false;
  bool _termsOfUseChecked = false;
  bool _redirectClicked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _freeReferralCodes
        .addAll(await referral_code_service.getFreeReferralCodes());
    _fiftyOffReferralCodes
        .addAll(await referral_code_service.getFiftyOffReferralCodes());
    _twentyOffReferralCodes
        .addAll(await referral_code_service.getTwentyOffReferralCodes());
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.exit_to_app),
                  label: Text(S.of(context).managePayment),
                  onPressed: _redirectClicked
                      ? null
                      : () {
                          setState(() {
                            _redirectClicked = true;
                          });
                          try {
                            stripe_service.redirectToStripePortal();
                          } catch (e) {
                            setState(() {
                              _redirectClicked = false;
                            });
                          }
                        },
                ),
                if (_redirectClicked)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Transform.scale(
                      scale: 0.5,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              S.of(context).pickPlan,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioListTile<SubscriptionPlan>(
                  title: Text(S.of(context).minimumCourse),
                  value: SubscriptionPlan.minimum,
                  groupValue: widget.subscriptionPlan,
                  onChanged: widget.onSubscriptionPlanChange,
                ),
                RadioListTile<SubscriptionPlan>(
                  title: Text(S.of(context).minimumPreschoolCourse),
                  value: SubscriptionPlan.minimumPreschool,
                  groupValue: widget.subscriptionPlan,
                  onChanged: widget.onSubscriptionPlanChange,
                ),
                RadioListTile<SubscriptionPlan>(
                  title: Text(S.of(context).monthlyCourse),
                  value: SubscriptionPlan.monthly,
                  groupValue: widget.subscriptionPlan,
                  onChanged: widget.onSubscriptionPlanChange,
                ),
              ],
            ),
            TextFormField(
              decoration: InputDecoration(
                icon: const Icon(Icons.percent),
                labelText: S.of(context).referralLabel,
                errorText:
                    _invalidReferral ? S.of(context).referralValidation : null,
                suffixIcon: _referralType != null
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  if (_freeReferralCodes.contains(value)) {
                    _referralType = referralTypeFree;
                  } else if (_fiftyOffReferralCodes.contains(value)) {
                    _referralType = referralType50;
                  } else if (_twentyOffReferralCodes.contains(value) &&
                      account.myUser!.referralCode != value) {
                    _referralType = referralType20;
                  } else {
                    _referralType = null;
                  }
                  widget.setReferralType(_referralType);
                  _invalidReferral = value.isNotEmpty && _referralType == null;
                });
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                icon: const Icon(Icons.person_add_alt),
                labelText: S.of(context).referrerLabel,
                hintText: S.of(context).referrerHint,
              ),
              onChanged: (value) => widget.setReferrer(value),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Checkbox(
                  value: _termsOfUseChecked,
                  onChanged: (value) {
                    setState(() {
                      _termsOfUseChecked = value ?? false;
                    });
                  },
                ),
                InkWell(
                  child: Text(
                    S.of(context).agreeToTerms,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, constants.routeInfo);
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              S.of(context).freeTrial,
            ),
            Text(
              S.of(context).freePoints,
            ),
            Text(
              S.of(context).signUpFee,
              style: _referralType != null
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            if (_referralType == referralType20)
              Text(S.of(context).signUpFeeDiscount(20, 40)),
            if (_referralType == referralType50)
              Text(S.of(context).signUpFeeDiscount(50, 25)),
            if (_referralType == referralTypeFree)
              Text(S.of(context).signUpFeeDiscount(100, 0)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    label: Text(S.of(context).stripePurchase),
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: widget.redirectClicked || !_termsOfUseChecked
                        ? null
                        : widget.onStripeSubmitClicked,
                  ),
                  if (widget.redirectClicked)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Transform.scale(
                        scale: 0.5,
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
