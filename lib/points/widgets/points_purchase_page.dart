import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/profile/data/profile_model.dart';
import 'package:success_academy/profile/services/purchase_service.dart'
    as stripe_service;

class PointsPurchasePage extends StatefulWidget {
  const PointsPurchasePage({super.key});

  @override
  State<PointsPurchasePage> createState() => _PointsPurchasePageState();
}

class _PointsPurchasePageState extends State<PointsPurchasePage> {
  final List<bool> _selectedToggle = [true, false];

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();
    assert(account.userType == UserType.student);

    return Center(
      child: Card(
        child: Container(
          width: 700,
          height: 700,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        S.of(context).addPoints,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ToggleButtons(
                        onPressed: (index) {
                          setState(() {
                            for (var i = 0; i < _selectedToggle.length; i++) {
                              _selectedToggle[i] = i == index;
                            }
                          });
                        },
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        constraints: const BoxConstraints(
                          minHeight: 40,
                          minWidth: 160,
                        ),
                        isSelected: _selectedToggle,
                        children: [
                          Text(S.of(context).oneTimePointsPurchase),
                          Text(S.of(context).pointSubscriptionTitle),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                RichText(
                  text: TextSpan(
                    text: '${S.of(context).eventPointsLabel}     ',
                    style: Theme.of(context).textTheme.titleMedium,
                    children: [
                      TextSpan(
                        text: '${account.studentProfile!.numPoints}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                if (_selectedToggle[0])
                  const _OneTimePointsPurchase()
                else
                  const _SubscriptionPointsPurchase(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OneTimePointsPurchase extends StatefulWidget {
  const _OneTimePointsPurchase();

  @override
  State<_OneTimePointsPurchase> createState() => _OneTimePointsPurchaseState();
}

class _OneTimePointsPurchaseState extends State<_OneTimePointsPurchase> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _redirectClicked = false;
  int _numPoints = 10;
  static const Map<int, String> _pointsCouponMap = {
    700: 'promo_1NNqXoK9gCxRnlEiD3tVodGw',
    1000: 'promo_1MaUbkK9gCxRnlEipn32mBEV',
    1500: 'promo_1NNqYfK9gCxRnlEiHZ0Im4f0',
    2000: 'promo_1MaUbzK9gCxRnlEi5Xd3CAdJ',
    5000: 'promo_1MaUc8K9gCxRnlEiiipU5lt3',
    10000: 'promo_1MaUcHK9gCxRnlEiK2ybiGGA',
  };

  void _onPointsChanged(int? value) {
    setState(() {
      _numPoints = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              children: [
                RadioListTile<int>(
                  title: Text(S.of(context).pointsPurchase(10, 1)),
                  value: 10,
                  groupValue: _numPoints,
                  onChanged: _onPointsChanged,
                ),
                RadioListTile<int>(
                  title: Text(S.of(context).pointsPurchase(100, 10)),
                  value: 100,
                  groupValue: _numPoints,
                  onChanged: _onPointsChanged,
                ),
                RadioListTile<int>(
                  title: Text(S.of(context).pointsPurchase(700, 69)),
                  value: 700,
                  groupValue: _numPoints,
                  onChanged: _onPointsChanged,
                ),
                RadioListTile<int>(
                  title: Text(S.of(context).pointsPurchase(1000, 98)),
                  value: 1000,
                  groupValue: _numPoints,
                  onChanged: _onPointsChanged,
                ),
                RadioListTile<int>(
                  title: Text(S.of(context).pointsPurchase(1500, 147)),
                  value: 1500,
                  groupValue: _numPoints,
                  onChanged: _onPointsChanged,
                ),
                RadioListTile<int>(
                  title: Text(S.of(context).pointsPurchase(2000, 194)),
                  value: 2000,
                  groupValue: _numPoints,
                  onChanged: _onPointsChanged,
                ),
                RadioListTile<int>(
                  title: Text(S.of(context).pointsPurchase(5000, 480)),
                  value: 5000,
                  groupValue: _numPoints,
                  onChanged: _onPointsChanged,
                ),
                RadioListTile<int>(
                  title: Text(S.of(context).pointsPurchase(10000, 920)),
                  value: 10000,
                  groupValue: _numPoints,
                  onChanged: _onPointsChanged,
                ),
              ],
            ),
            const SizedBox(
              height: 30,
            ),
            if (_redirectClicked)
              const CircularProgressIndicator()
            else
              FilledButton.tonalIcon(
                label: Text(S.of(context).stripePointsPurchase),
                icon: const Icon(Icons.exit_to_app),
                onPressed: account.shouldShowContent()
                    ? () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _redirectClicked = true;
                          });
                          try {
                            await stripe_service
                                .startStripePointsCheckoutSession(
                              userId: account.firebaseUser!.uid,
                              profileId: account.studentProfile!.profileId,
                              quantity: _numPoints,
                              coupon: _pointsCouponMap[_numPoints],
                            );
                          } catch (err) {
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
                              'Failed to start Stripe points purchase: $err',
                            );
                          }
                        }
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionPointsPurchase extends StatefulWidget {
  const _SubscriptionPointsPurchase();

  @override
  State<_SubscriptionPointsPurchase> createState() =>
      _SubscriptionPointsPurchaseState();
}

class _SubscriptionPointsPurchaseState
    extends State<_SubscriptionPointsPurchase> {
  final String _orderPointSubscriptionPrivateOnlyPriceId =
      'price_1ORJuSK9gCxRnlEil2SsaBPY';
  final String _supplementaryPointSubscriptionPrivateOnlyPriceId =
      'price_1ORQnwK9gCxRnlEiVXVbQUk5';
  final String _orderPointSubscriptionFreeAndPrivatePriceId =
      'price_1OhO7iK9gCxRnlEi6oyV1cxe';
  final String _supplementaryPointSubscriptionFreeAndPrivatePriceId =
      'price_1OhOD6K9gCxRnlEiwx2UOsR0';
  late final Map<String, int> _priceIdToPointsMap;
  late String _selectedPrice;
  int _selectedNumber = 2;
  bool _redirectClicked = false;

  @override
  void initState() {
    super.initState();
    final account = context.read<AccountModel>();
    _selectedPrice = account.subscriptionPlan == SubscriptionPlan.monthly
        ? _orderPointSubscriptionPrivateOnlyPriceId
        : _orderPointSubscriptionFreeAndPrivatePriceId;
    _priceIdToPointsMap = {
      _orderPointSubscriptionPrivateOnlyPriceId: 280,
      _supplementaryPointSubscriptionPrivateOnlyPriceId: 170,
      _orderPointSubscriptionFreeAndPrivatePriceId: 252,
      _supplementaryPointSubscriptionFreeAndPrivatePriceId: 153,
    };
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Form(
      child: Column(
        children: [
          if (account.pointSubscriptionPriceId != null)
            Text(
              S.of(context).currentPointSubscription(
                    account.pointSubscriptionQuantity!,
                  ),
              style: Theme.of(context).textTheme.titleMedium,
            )
          else
            Text(
              S.of(context).currentPointSubscription('0'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 25),
          Text(S.of(context).pointSubscriptionTrial),
          Text(S.of(context).removePointSubscription),
          const SizedBox(height: 25),
          if (account.subscriptionPlan == SubscriptionPlan.monthly)
            DropdownMenu<String>(
              requestFocusOnTap: true,
              initialSelection: _orderPointSubscriptionPrivateOnlyPriceId,
              label: Text(S.of(context).type),
              onSelected: (value) {
                setState(() {
                  _selectedPrice = value!;
                });
              },
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: _orderPointSubscriptionPrivateOnlyPriceId,
                  label: S.of(context).orderPointSubscriptionPrivateOnly,
                ),
                DropdownMenuEntry(
                  value: _supplementaryPointSubscriptionPrivateOnlyPriceId,
                  label: S
                      .of(context)
                      .freeSupplementaryPointSubscriptionPrivateOnly,
                ),
              ],
            )
          else
            DropdownMenu<String>(
              requestFocusOnTap: true,
              initialSelection: _orderPointSubscriptionFreeAndPrivatePriceId,
              label: Text(S.of(context).type),
              onSelected: (value) {
                setState(() {
                  _selectedPrice = value!;
                });
              },
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: _orderPointSubscriptionFreeAndPrivatePriceId,
                  label: S.of(context).orderPointSubscriptionFreeAndPrivate,
                ),
                DropdownMenuEntry(
                  value: _supplementaryPointSubscriptionFreeAndPrivatePriceId,
                  label: S
                      .of(context)
                      .freeSupplementaryPointSubscriptionFreeAndPrivate,
                ),
              ],
            ),
          const SizedBox(
            height: 20,
          ),
          DropdownMenu<int>(
            requestFocusOnTap: true,
            initialSelection: 2,
            width: 200,
            label: Text(S.of(context).blockCount),
            onSelected: (value) {
              setState(() {
                _selectedNumber = value!;
              });
            },
            dropdownMenuEntries: [0, 2, 4, 6, 8, 12]
                .map(
                  (e) => DropdownMenuEntry(value: e, label: e.toString()),
                )
                .toList(),
          ),
          const SizedBox(
            height: 20,
          ),
          if (_redirectClicked)
            const CircularProgressIndicator(
              value: null,
            )
          else
            FilledButton.tonalIcon(
              onPressed: account.pointSubscriptionPriceId != null
                  ? null
                  : account.shouldShowContent()
                      ? () async {
                          try {
                            setState(() {
                              _redirectClicked = true;
                            });
                            final pointQuantity = _selectedNumber *
                                _priceIdToPointsMap[_selectedPrice]!;
                            await stripe_service
                                .startStripePointSubscriptionCheckoutSession(
                              userId: account.firebaseUser!.uid,
                              profileId: account.studentProfile!.profileId,
                              priceId: _selectedPrice,
                              quantity: pointQuantity,
                            );
                            account.pointSubscriptionQuantity = pointQuantity;
                            setState(() {
                              _redirectClicked = false;
                            });
                          } catch (err) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  S.of(context).stripeRedirectFailure,
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                            setState(() {
                              _redirectClicked = false;
                            });
                            debugPrint(
                              'Failed to start Stripe point subscription checkout $err',
                            );
                          }
                        }
                      : null,
              label: Text(S.of(context).stripePurchase),
              icon: const Icon(Icons.exit_to_app),
            ),
        ],
      ),
    );
  }
}
