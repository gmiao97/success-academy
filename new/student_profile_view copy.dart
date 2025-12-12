import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/profile/services/profile_service.dart'
    as profile_service;
import 'package:success_academy/profile/services/purchase_service.dart'
    as stripe_service;

import '../../account/data/account_model.dart';
import '../../constants.dart' as constants;
import '../../generated/l10n.dart';
import '../data/profile_model.dart';
import 'create_subscription_form.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FA), Color(0xFFE4E8EC)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘッダーカード
            _buildHeaderCard(context, account, isMobile),
            const SizedBox(height: 20),
            // メインコンテンツグリッド
            isMobile
                ? _buildMobileLayout(context, account)
                : _buildDesktopLayout(context, account),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ヘッダーカード
  Widget _buildHeaderCard(BuildContext context, AccountModel account, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      child: isMobile
          ? Column(
              children: [
                _buildAvatar(context, account),
                const SizedBox(height: 12),
                _buildNameAndBadge(context, account, true),
                const SizedBox(height: 15),
                _buildSwitchProfileButton(context, account),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildAvatar(context, account),
                    const SizedBox(width: 20),
                    _buildNameAndBadge(context, account, false),
                  ],
                ),
                _buildSwitchProfileButton(context, account),
              ],
            ),
    );
  }

  // アバター
  Widget _buildAvatar(BuildContext context, AccountModel account) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          account.studentProfile!.lastName[0],
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667EEA),
          ),
        ),
      ),
    );
  }

  // 名前とバッジ
  Widget _buildNameAndBadge(BuildContext context, AccountModel account, bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          '${account.studentProfile!.lastName} ${account.studentProfile!.firstName}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '👨‍🎓 ${S.of(context).student}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // プロフィール切替ボタン
  Widget _buildSwitchProfileButton(BuildContext context, AccountModel account) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      icon: const Icon(Icons.swap_horiz, color: Colors.white),
      label: Text(
        S.of(context).switchProfile,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () {
        account.studentProfile = null;
      },
    );
  }

  // デスクトップレイアウト（2列）
  Widget _buildDesktopLayout(BuildContext context, AccountModel account) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildBasicInfoCard(context, account)),
            const SizedBox(width: 20),
            Expanded(child: _buildReferralCodeCard(context, account)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildReferrerCard(context, account)),
            const SizedBox(width: 20),
            Expanded(child: _buildSubscriptionCard(context, account)),
          ],
        ),
      ],
    );
  }

  // モバイルレイアウト（1列）
  Widget _buildMobileLayout(BuildContext context, AccountModel account) {
    return Column(
      children: [
        _buildBasicInfoCard(context, account),
        const SizedBox(height: 20),
        _buildReferralCodeCard(context, account),
        const SizedBox(height: 20),
        _buildReferrerCard(context, account),
        const SizedBox(height: 20),
        _buildSubscriptionCard(context, account),
      ],
    );
  }

  // 基本カードスタイル
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // セクションタイトル
  Widget _sectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF667EEA),
          ),
        ),
      ],
    );
  }

  // 基本情報カード
  Widget _buildBasicInfoCard(BuildContext context, AccountModel account) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📋', S.of(context).profile),
          const SizedBox(height: 20),
          _infoRow(
            '🎂',
            S.of(context).dateOfBirthLabel,
            constants.dateFormatter.format(account.studentProfile!.dateOfBirth),
          ),
          const SizedBox(height: 15),
          _infoRow(
            '⭐',
            S.of(context).eventPointsLabel,
            '${account.studentProfile!.numPoints} pt',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  // 情報行
  Widget _infoRow(String emoji, String label, String value, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '$emoji $label',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              color: isHighlighted ? const Color(0xFF667EEA) : Colors.grey[800],
              fontSize: isHighlighted ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  // 紹介コードカード
  Widget _buildReferralCodeCard(BuildContext context, AccountModel account) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🎁', S.of(context).myCode),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(isMobile ? 15 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).myCode,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        account.myUser?.referralCode ?? '',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: const Color(0xFF667EEA),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildCopyButton(context, account, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // コピーボタン
  Widget _buildCopyButton(BuildContext context, AccountModel account, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          onTap: () {
            Clipboard.setData(
              ClipboardData(text: account.myUser!.referralCode),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).copied),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: isMobile ? 8 : 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.copy,
                  color: Colors.white,
                  size: isMobile ? 14 : 16,
                ),
                const SizedBox(width: 6),
                Text(
                  S.of(context).copy,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 紹介者カード
  Widget _buildReferrerCard(BuildContext context, AccountModel account) {
    final referrer = account.studentProfile!.referrer;
    
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🤝', S.of(context).referrerLabel),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      referrer != null && referrer.isNotEmpty ? referrer[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).referrerLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        referrer ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // サブスクリプションカード
  Widget _buildSubscriptionCard(BuildContext context, AccountModel account) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('💳', S.of(context).manageSubscription),
          const SizedBox(height: 20),
          account.subscriptionPlan != null
              ? _ManageSubscription(
                  subscriptionPlan: account.subscriptionPlan!,
                )
              : CreateSubscriptionForm(
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
                    final updatedStudentProfile = account.studentProfile!;
                    updatedStudentProfile.referrer = _referrer;
                    try {
                      await profile_service.updateStudentProfile(
                        account.firebaseUser!.uid,
                        updatedStudentProfile,
                      );
                      account.studentProfile = updatedStudentProfile;
                      await stripe_service.startStripeSubscriptionCheckoutSession(
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
                          content: Text(S.of(context).stripeRedirectFailure),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                      debugPrint('Failed to start Stripe subscription checkout $e');
                    }
                  },
                ),
        ],
      ),
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 現在のプランカード
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).pickPlan,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                getSubscriptionPlanName(context, widget.subscriptionPlan),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        // 管理ボタン
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _redirectClicked
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_redirectClicked)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.settings, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        S.of(context).manageSubscription,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
