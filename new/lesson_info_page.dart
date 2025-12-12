import 'package:editable/editable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/lesson_info/services/lesson_info_service.dart'
    as lesson_info_service;
import 'package:url_launcher/url_launcher.dart';

import '../../account/data/account_model.dart';
import '../../generated/l10n.dart';
import '../../profile/data/profile_model.dart';
import '../data/lesson_model.dart';

class LessonInfoPage extends StatefulWidget {
  const LessonInfoPage({super.key});

  @override
  State<LessonInfoPage> createState() => _LessonInfoPageState();
}

class _LessonInfoPageState extends State<LessonInfoPage> {
  bool _zoomInfoLoaded = false;
  List<LessonModel> _zoomInfo = [];
  bool _showAllRules = false;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final account = context.watch<AccountModel>();
    final lessons = await lesson_info_service.getLessons(
      includePreschool: account.userType != UserType.student ||
          account.subscriptionPlan == SubscriptionPlan.minimumPreschool,
    );
    setState(() {
      _zoomInfo = lessons;
      _zoomInfoLoaded = true;
    });
  }

  Widget _getZoomInfoView(
    UserType userType,
    SubscriptionPlan? subscriptionPlan,
    bool isMobile,
    String locale,
  ) {
    if (userType == UserType.admin) {
      return EditableZoomInfo(
        zoomInfo: _zoomInfo,
      );
    }
    if (userType == UserType.teacher ||
        (subscriptionPlan != null &&
            subscriptionPlan != SubscriptionPlan.monthly)) {
      return _ModernZoomInfo(
        zoomInfo: _zoomInfo,
        isMobile: isMobile,
        locale: locale,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final locale = account.locale;

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
                _buildHeader(context, isMobile, locale),
                const SizedBox(height: 20),
                // ルールセクション
                _buildRulesSection(context, isMobile, locale),
                const SizedBox(height: 20),
                // Zoom情報
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text('🎥', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Text(
                            locale == 'ja' ? 'Zoom情報' : 'Zoom Information',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      !_zoomInfoLoaded
                          ? const Center(child: CircularProgressIndicator())
                          : _getZoomInfoView(
                              account.userType,
                              account.subscriptionPlan,
                              isMobile,
                              locale,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, String locale) {
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
              const Text('📚', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Text(
                S.of(context).lessonInfo,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          // ボタン
          isMobile
              ? Row(
                  children: [
                    Expanded(
                      child: _buildHeaderButton(
                        context,
                        '📅',
                        S.of(context).freeLessonTimeTable,
                        'https://drive.google.com/embeddedfolderview?id=1z5WUmx_lFVRy3YbmtEUH-tIqrwsaP8au#list',
                        isMobile,
                        true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeaderButton(
                        context,
                        '📚',
                        S.of(context).freeLessonMaterials,
                        'https://drive.google.com/embeddedfolderview?id=1EMhq3GkTEfsk5NiSHpqyZjS4H2N_aSak#list',
                        isMobile,
                        true,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeaderButton(
                      context,
                      '📅',
                      S.of(context).freeLessonTimeTable,
                      'https://drive.google.com/embeddedfolderview?id=1z5WUmx_lFVRy3YbmtEUH-tIqrwsaP8au#list',
                      isMobile,
                      false,
                    ),
                    const SizedBox(width: 16),
                    _buildHeaderButton(
                      context,
                      '📚',
                      S.of(context).freeLessonMaterials,
                      'https://drive.google.com/embeddedfolderview?id=1EMhq3GkTEfsk5NiSHpqyZjS4H2N_aSak#list',
                      isMobile,
                      false,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context,
    String emoji,
    String label,
    String url,
    bool isMobile,
    bool isTransparent,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (!await launchUrl(Uri.parse(url))) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  content: Text(S.of(context).openLinkFailure),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 32,
            vertical: isMobile ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: isTransparent
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
            boxShadow: isTransparent
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: TextStyle(fontSize: isMobile ? 18 : 20)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isTransparent ? Colors.white : const Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesSection(BuildContext context, bool isMobile, String locale) {
    final quickRules = [
      {'emoji': '⏰', 'text': locale == 'ja' ? '5分前予約' : '5min before'},
      {'emoji': '🚪', 'text': locale == 'ja' ? '2分前入室' : 'Enter 2min before'},
      {'emoji': '📹', 'text': locale == 'ja' ? 'ビデオON' : 'Video ON'},
    ];

    final allRules = [
      {
        'emoji': '⏰',
        'title': locale == 'ja' ? '5分前までに予約' : 'Reserve 5 min before',
        'desc': locale == 'ja' ? '予約・キャンセルは開始5分前まで。' : 'Reserve and cancel by 5 minutes before class.',
      },
      {
        'emoji': '🚪',
        'title': locale == 'ja' ? '2分前から入室可能' : 'Enter 2 min before',
        'desc': locale == 'ja' ? 'それより早く入ると中断される場合あり。' : 'Enter Zoom room from 2 minutes before.',
      },
      {
        'emoji': '📹',
        'title': locale == 'ja' ? 'ビデオON' : 'Video ON',
        'desc': locale == 'ja' ? 'セキュリティと理解度把握のため。' : 'Keep video on for better communication.',
      },
      {
        'emoji': '🔇',
        'title': locale == 'ja' ? '発言時以外ミュート' : 'Mute when not speaking',
        'desc': locale == 'ja' ? '講師の声を明瞭にするため。' : 'Keep muted except when speaking.',
      },
      {
        'emoji': '👤',
        'title': locale == 'ja' ? 'お名前表示' : 'Display name',
        'desc': locale == 'ja' ? 'ひらがな/ローマ字で。' : 'Set display name to child\'s name.',
      },
      {
        'emoji': '⚠️',
        'title': locale == 'ja' ? '5分後クローズ' : 'Closes after 5min',
        'desc': locale == 'ja' ? '参加者なしで自動終了。' : 'Class closes if no participants after 5 min.',
      },
      {
        'emoji': '🔐',
        'title': locale == 'ja' ? 'PW毎週更新' : 'Weekly PW update',
        'desc': locale == 'ja' ? '日曜日に変更。' : 'Password changes every Sunday.',
      },
      {
        'emoji': '👀',
        'title': locale == 'ja' ? '見守りのお願い' : 'Monitor lessons',
        'desc': locale == 'ja' ? '時々お子様の様子を確認。' : 'Please occasionally check on your child.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // クイックルール
        if (isMobile) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📋', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: quickRules.map((rule) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
                    ),
                    child: Text(
                      '${rule['emoji']} ${rule['text']}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showAllRules = !_showAllRules),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _showAllRules
                    ? (locale == 'ja' ? '▲ 閉じる' : '▲ Close')
                    : (locale == 'ja' ? '▼ 全ルールを見る' : '▼ View all rules'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667EEA),
                ),
              ),
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '📋 ${locale == 'ja' ? '受講ルール:' : 'Lesson Rules:'}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 12),
              ...quickRules.map((rule) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
                      ),
                      child: Text(
                        '${rule['emoji']} ${rule['text']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                    ),
                  )),
              GestureDetector(
                onTap: () => setState(() => _showAllRules = !_showAllRules),
                child: Text(
                  _showAllRules
                      ? (locale == 'ja' ? '閉じる' : 'Close')
                      : (locale == 'ja' ? '全ルールを見る' : 'View all rules'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667EEA),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
        // アコーディオン
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: allRules.map((rule) => Container(
                      width: isMobile ? double.infinity : 320,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rule['emoji'] as String, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rule['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rule['desc'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
              ),
            ),
          ),
          crossFadeState: _showAllRules ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}

class _ModernZoomInfo extends StatelessWidget {
  final List<LessonModel> zoomInfo;
  final bool isMobile;
  final String locale;

  const _ModernZoomInfo({
    required this.zoomInfo,
    required this.isMobile,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: zoomInfo
          .map((lesson) => _ModernLessonCard(
                lesson: lesson,
                isMobile: isMobile,
                locale: locale,
              ))
          .toList(),
    );
  }
}

class _ModernLessonCard extends StatefulWidget {
  final LessonModel lesson;
  final bool isMobile;
  final String locale;

  const _ModernLessonCard({
    required this.lesson,
    required this.isMobile,
    required this.locale,
  });

  @override
  State<_ModernLessonCard> createState() => _ModernLessonCardState();
}

class _ModernLessonCardState extends State<_ModernLessonCard> {
  String? _copiedField;

  void _copyToClipboard(String text, String field) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedField = field);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedField = null);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.locale == 'ja' ? 'コピーしました' : 'Copied!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(widget.isMobile ? 15 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.08),
            const Color(0xFF764BA2).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: widget.isMobile
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // レッスン名
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.lesson.name.isNotEmpty ? widget.lesson.name[0] : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 200,
          child: Text(
            widget.lesson.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
              fontSize: 17,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 20),
        // ID
        _buildInfoChip(
          'ID',
          widget.lesson.zoomId,
          const Color(0xFF667EEA),
          'id',
        ),
        const SizedBox(width: 12),
        // PW
        _buildInfoChip(
          'PW',
          widget.lesson.zoomPassword,
          const Color(0xFFFF8C42),
          'pw',
        ),
        const Spacer(),
        // 参加ボタン
        _buildJoinButton(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // レッスン名
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.lesson.name.isNotEmpty ? widget.lesson.name[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.lesson.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ID
        _buildMobileInfoRow('🔢', 'ID', widget.lesson.zoomId, const Color(0xFF667EEA), 'id'),
        const SizedBox(height: 10),
        // PW
        _buildMobileInfoRow('🔒', 'PW', widget.lesson.zoomPassword, const Color(0xFFFF8C42), 'pw'),
        const SizedBox(height: 10),
        // 参加ボタン
        _buildJoinButton(),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, Color color, String field) {
    final isCopied = _copiedField == field;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _copyToClipboard(value, field),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCopied ? const Color(0xFF4CAF50) : color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isCopied ? '✓' : '📋',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(String emoji, String label, String value, Color color, String field) {
    final isCopied = _copiedField == field;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji $label',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _copyToClipboard(value, field),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCopied ? const Color(0xFF4CAF50) : color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCopied ? '✓' : '📋',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (!await launchUrl(Uri.parse(widget.lesson.zoomLink))) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  content: Text(S.of(context).openLinkFailure),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 20 : 20,
            vertical: widget.isMobile ? 14 : 12,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: widget.isMobile ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                widget.locale == 'ja' ? 'Zoomに参加' : 'Join Zoom',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditableZoomInfo extends StatelessWidget {
  final List<LessonModel> zoomInfo;

  const EditableZoomInfo({
    super.key,
    required this.zoomInfo,
  });

  @override
  Widget build(BuildContext context) {
    final headers = [
      {
        'title': S.of(context).lesson,
        'widthFactor': 0.15,
        'index': 1,
        'key': 'name',
      },
      {
        'title': S.of(context).link,
        'widthFactor': 0.3,
        'index': 2,
        'key': 'zoom_link',
      },
      {
        'title': S.of(context).meetingId,
        'widthFactor': 0.1,
        'index': 3,
        'key': 'zoom_id',
      },
      {
        'title': S.of(context).password,
        'index': 4,
        'key': 'zoom_pw',
      },
    ];

    return Column(
      children: [
        Text(
          S.of(context).freeLessonZoomInfo,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(
          height: 500,
          child: Editable(
            columns: headers,
            rows: zoomInfo.map((lesson) => lesson.toJson()).toList(),
            showSaveIcon: true,
            saveIconColor: Theme.of(context).primaryColor,
            onRowSaved: (value) async {
              if (value == 'no edit') {
                return;
              }

              final i = value['row'];
              value.remove('row');

              value.forEach((k, v) {
                switch (k) {
                  case 'name':
                    zoomInfo[i].name = v;
                    break;
                  case 'zoom_link':
                    zoomInfo[i].zoomLink = v;
                    break;
                  case 'zoom_id':
                    zoomInfo[i].zoomId = v;
                    break;
                  case 'zoom_pw':
                    zoomInfo[i].zoomPassword = v;
                    break;
                }
              });
              try {
                await lesson_info_service.updateLesson(
                  zoomInfo[i].id,
                  zoomInfo[i],
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        S.of(context).lessonInfoUpdated,
                      ),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Failed to update lesson info: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).lessonInfoUpdateFailed),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            onSubmitted: ((value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    S.of(context).promptSave,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
