import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../account/data/account_model.dart';
import '../../generated/l10n.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/services/purchase_service.dart' as stripe_service;

class PointsPurchasePage extends StatefulWidget {
  const PointsPurchasePage({super.key});

  @override
  State<PointsPurchasePage> createState() => _PointsPurchasePageState();
}

class _PointsPurchasePageState extends State<PointsPurchasePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final locale = account.locale;
    assert(account.userType == UserType.student);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FA), Color(0xFFE4E8EC)],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ヘッダー
                _buildHeader(context, account, isMobile, locale),
                const SizedBox(height: 25),
                // タブ切り替え
                _buildTabSelector(context, isMobile, locale),
                const SizedBox(height: 25),
                // コンテンツ
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isMobile ? 20 : 30),
                  child: _selectedTab == 0
                      ? _OneTimePointsPurchase(isMobile: isMobile, locale: locale)
                      : _SubscriptionPointsPurchase(isMobile: isMobile, locale: locale),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AccountModel account, bool isMobile, String locale) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Text(
                S.of(context).addPoints,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 現在のポイント表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(
                  locale == 'ja' ? '現在のポイント' : 'Current Points',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${account.studentProfile!.numPoints}',
                    style: const TextStyle(
                      color: Color(0xFF667EEA),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context, bool isMobile, String locale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _selectedTab == 0
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🛒',
                      style: TextStyle(fontSize: isMobile ? 18 : 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      S.of(context).oneTimePointsPurchase,
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : const Color(0xFF666666),
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _selectedTab == 1
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🔄',
                      style: TextStyle(fontSize: isMobile ? 18 : 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      S.of(context).pointSubscriptionTitle,
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : const Color(0xFF666666),
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OneTimePointsPurchase extends StatefulWidget {
  final bool isMobile;
  final String locale;

  const _OneTimePointsPurchase({
    required this.isMobile,
    required this.locale,
  });

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

  static const List<Map<String, dynamic>> _pointOptions = [
    {'points': 10, 'price': 1, 'popular': false},
    {'points': 100, 'price': 10, 'popular': false},
    {'points': 700, 'price': 69, 'popular': false},
    {'points': 1000, 'price': 98, 'popular': true},
    {'points': 1500, 'price': 147, 'popular': false},
    {'points': 2000, 'price': 194, 'popular': false},
    {'points': 5000, 'price': 480, 'popular': false},
    {'points': 10000, 'price': 920, 'popular': false},
  ];

  void _onPointsChanged(int value) {
    setState(() {
      _numPoints = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // ポイント選択グリッド
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isMobile ? 2 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: widget.isMobile ? 1.5 : 2.2,
            ),
            itemCount: _pointOptions.length,
            itemBuilder: (context, index) {
              final option = _pointOptions[index];
              final isSelected = _numPoints == option['points'];
              final isPopular = option['popular'] as bool;
              
              return GestureDetector(
                onTap: () => _onPointsChanged(option['points'] as int),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFF667EEA).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '⭐ ${option['points']}',
                            style: TextStyle(
                              fontSize: widget.isMobile ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF333333),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${option['price']}',
                            style: TextStyle(
                              fontSize: widget.isMobile ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : const Color(0xFF667EEA),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (isPopular)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B6B),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(14),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            widget.locale == 'ja' ? '人気' : 'Popular',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          // 購入ボタン
          _redirectClicked
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                )
              : SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: account.shouldShowContent()
                          ? () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _redirectClicked = true;
                                });
                                try {
                                  await stripe_service.startStripePointsCheckoutSession(
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
                                      content: Text(S.of(context).stripeRedirectFailure),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                  debugPrint('Failed to start Stripe points purchase: $err');
                                }
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💳', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Text(
                              S.of(context).stripePointsPurchase,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SubscriptionPointsPurchase extends StatefulWidget {
  final bool isMobile;
  final String locale;

  const _SubscriptionPointsPurchase({
    required this.isMobile,
    required this.locale,
  });

  @override
  State<_SubscriptionPointsPurchase> createState() =>
      _SubscriptionPointsPurchaseState();
}

class _SubscriptionPointsPurchaseState extends State<_SubscriptionPointsPurchase> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 現在のサブスクリプション状況
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667EEA).withOpacity(0.1),
                const Color(0xFF764BA2).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.locale == 'ja' ? '現在のサブスクリプション' : 'Current Subscription',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.pointSubscriptionPriceId != null
                          ? S.of(context).currentPointSubscription(
                                account.pointSubscriptionQuantity!,
                              )
                          : S.of(context).currentPointSubscription('0'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // タイプ選択
        Text(
          widget.locale == 'ja' ? 'タイプを選択' : 'Select Type',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
          ),
          child: account.subscriptionPlan == SubscriptionPlan.monthly
              ? DropdownButtonFormField<String>(
                  value: _selectedPrice,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedPrice = value!;
                    });
                  },
                  items: [
                    DropdownMenuItem(
                      value: _orderPointSubscriptionPrivateOnlyPriceId,
                      child: Text(S.of(context).orderPointSubscriptionPrivateOnly),
                    ),
                    DropdownMenuItem(
                      value: _supplementaryPointSubscriptionPrivateOnlyPriceId,
                      child: Text(S.of(context).freeSupplementaryPointSubscriptionPrivateOnly),
                    ),
                  ],
                )
              : DropdownButtonFormField<String>(
                  value: _selectedPrice,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedPrice = value!;
                    });
                  },
                  items: [
                    DropdownMenuItem(
                      value: _orderPointSubscriptionFreeAndPrivatePriceId,
                      child: Text(S.of(context).orderPointSubscriptionFreeAndPrivate),
                    ),
                    DropdownMenuItem(
                      value: _supplementaryPointSubscriptionFreeAndPrivatePriceId,
                      child: Text(S.of(context).freeSupplementaryPointSubscriptionFreeAndPrivate),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        // ブロック数選択
        Text(
          S.of(context).blockCount,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedNumber,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _selectedNumber = value!;
              });
            },
            items: [0, 2, 4, 6, 8, 12]
                .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                .toList(),
          ),
        ),
        const SizedBox(height: 30),
        // 購入ボタン
        _redirectClicked
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                ),
              )
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: account.pointSubscriptionPriceId != null
                      ? null
                      : account.shouldShowContent()
                          ? () async {
                              try {
                                setState(() {
                                  _redirectClicked = true;
                                });
                                int pointQuantity =
                                    _selectedNumber * _priceIdToPointsMap[_selectedPrice]!;
                                await stripe_service.startStripePointSubscriptionCheckoutSession(
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
                                    content: Text(S.of(context).stripeRedirectFailure),
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                );
                                setState(() {
                                  _redirectClicked = false;
                                });
                                debugPrint('Failed to start Stripe point subscription checkout $err');
                              }
                            }
                          : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: account.pointSubscriptionPriceId != null
                          ? LinearGradient(
                              colors: [Colors.grey.shade400, Colors.grey.shade500],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                            ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: account.pointSubscriptionPriceId != null
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💳', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text(
                          S.of(context).stripePurchase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
