import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/constants.dart' as constants;
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/profile/data/profile_model.dart';
import 'package:success_academy/profile/services/profile_service.dart'
    as profile_service;
import 'package:success_academy/profile/services/purchase_service.dart'
    as stripe_service;
import 'package:success_academy/profile/widgets/create_subscription_form.dart';

class StudentProfileView extends StatefulWidget {
  const StudentProfileView({super.key});

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  bool _redirectClicked = false;
  String? _referralType;
  String? _referrer;
  SubscriptionPlan _subscriptionPlan = SubscriptionPlan.minimum;

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                S.of(context).profile,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton.icon(
                icon: const Icon(Icons.rotate_left),
                label: Text(S.of(context).switchProfile),
                onPressed: () {
                  account.studentProfile = null;
                },
              ),
            ),
          ],
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CircleAvatar(
                        radius: 30,
                        child: Text(
                          account.studentProfile!.lastName[0],
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${account.studentProfile!.lastName}, ${account.studentProfile!.firstName}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      S.of(context).student,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Divider(),
                    RichText(
                      text: TextSpan(
                        text: '${S.of(context).dateOfBirthLabel} - ',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: constants.dateFormatter
                                .format(account.studentProfile!.dateOfBirth),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: '${S.of(context).eventPointsLabel} - ',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '${account.studentProfile!.numPoints}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '${S.of(context).myCode} - ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: account.myUser?.referralCode,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: account.myUser!.referralCode,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(S.of(context).copied),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                    RichText(
                      text: TextSpan(
                        text: '${S.of(context).referrerLabel} - ',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: account.studentProfile!.referrer ?? '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (account.subscriptionPlan != null)
                      _ManageSubscription(
                        subscriptionPlan: account.subscriptionPlan!,
                      )
                    else
                      CreateSubscriptionForm(
                        subscriptionPlan: _subscriptionPlan,
                        onSubscriptionPlanChange: (subscription) {
                          setState(() {
                            _subscriptionPlan = subscription!;
                          });
                        },
                        redirectClicked: _redirectClicked,
                        setReferralType: (referralType) {
                          _referralType = referralType;
                        },
                        setReferrer: (name) {
                          _referrer = name;
                        },
                        onStripeSubmitClicked: () async {
                          setState(() {
                            _redirectClicked = true;
                          });
                          final updatedStudentProfile = account.studentProfile!
                            ..referrer = _referrer
                            ..dateOfBirth
                            ..numPoints = 200;
                          try {
                            await profile_service.updateStudentProfile(
                              account.firebaseUser!.uid,
                              updatedStudentProfile,
                            );
                            account.studentProfile = updatedStudentProfile;
                            await stripe_service
                                .startStripeSubscriptionCheckoutSession(
                              userId: account.firebaseUser!.uid,
                              profileId: account.studentProfile!.profileId,
                              subscriptionPlan: _subscriptionPlan,
                              referralType: _referralType,
                            );
                          } catch (e) {
                            setState(() {
                              _redirectClicked = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  S.of(context).stripeRedirectFailure,
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                            debugPrint(
                              'Failed to start Stripe subscription checkout $e',
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManageSubscription extends StatefulWidget {
  final SubscriptionPlan subscriptionPlan;

  const _ManageSubscription({
    required this.subscriptionPlan,
  });

  @override
  State<_ManageSubscription> createState() => _ManageSubscriptionState();
}

class _ManageSubscriptionState extends State<_ManageSubscription> {
  bool _redirectClicked = false;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).manageSubscription,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                getSubscriptionPlanName(context, widget.subscriptionPlan),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.exit_to_app),
                    label: Text(S.of(context).manageSubscription),
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
            ],
          ),
        ),
      );
}
