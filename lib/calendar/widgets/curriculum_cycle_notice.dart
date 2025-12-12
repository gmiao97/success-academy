import 'package:flutter/material.dart';

class CurriculumCycleNotice extends StatefulWidget {
  final String locale;

  const CurriculumCycleNotice({
    super.key,
    required this.locale,
  });

  @override
  State<CurriculumCycleNotice> createState() => _CurriculumCycleNoticeState();
}

class _CurriculumCycleNoticeState extends State<CurriculumCycleNotice> {
  bool _isExpanded = false;

  // 現在の月から何ヶ月目かを計算 (1月,4月,7月,10月 = 1ヶ月目)
  int _getCurrentCycleMonth() {
    final month = DateTime.now().month;
    final cycleMonth = ((month - 1) % 3) + 1;
    return cycleMonth;
  }

  String _getCycleMonthLabel(int cycleMonth) {
    if (widget.locale == 'ja') {
      switch (cycleMonth) {
        case 1:
          return 'やさしい';
        case 2:
          return 'ふつう';
        case 3:
          return '難しい';
        default:
          return '';
      }
    } else {
      switch (cycleMonth) {
        case 1:
          return 'Basic';
        case 2:
          return 'Intermediate';
        case 3:
          return 'Advanced';
        default:
          return '';
      }
    }
  }

  Color _getCycleMonthColor(int cycleMonth) {
    switch (cycleMonth) {
      case 1:
        return const Color(0xFFBBF7D0); // さらに薄い緑
      case 2:
        return const Color(0xFFFF9800);
      case 3:
        return const Color(0xFFf44336);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCycleMonth = _getCurrentCycleMonth();
    final isJa = widget.locale == 'ja';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.08),
            const Color(0xFF764BA2).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // ヘッダー（常に表示）
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 400;
              
              return InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 18,
                    vertical: isMobile ? 10 : 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: _isExpanded
                        ? null
                        : LinearGradient(
                            colors: [
                              const Color(0xFF667EEA).withOpacity(0.1),
                              const Color(0xFF764BA2).withOpacity(0.05),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('📚', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isJa ? 'フリーレッスンは3ヶ月1クール制' : 'Free Lessons: 3-Month Cycle',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF667EEA),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color(0xFF667EEA),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCycleMonthColor(currentCycleMonth),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                isJa
                                    ? '今月: ${_getCycleMonthLabel(currentCycleMonth)}'
                                    : 'Now: ${_getCycleMonthLabel(currentCycleMonth)}',
                                style: TextStyle(
                                  color: currentCycleMonth == 1 ? const Color(0xFF166534) : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Text('📚', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Text(
                              isJa ? 'フリーレッスンは3ヶ月1クール制' : 'Free Lessons: 3-Month Cycle',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF667EEA),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCycleMonthColor(currentCycleMonth),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                isJa
                                    ? '今月: ${_getCycleMonthLabel(currentCycleMonth)}'
                                    : 'This month: ${_getCycleMonthLabel(currentCycleMonth)}',
                                style: TextStyle(
                                  color: currentCycleMonth == 1 ? const Color(0xFF166534) : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFF667EEA),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
          // 展開部分
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(currentCycleMonth, isJa),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(int currentCycleMonth, bool isJa) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF667EEA).withOpacity(0.12),
                const Color(0xFF764BA2).withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 説明文
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: isMobile ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isJa
                      ? '📝 フリーレッスンは3ヶ月で1クールです。月ごとに難易度が上がります。'
                      : '📝 Free lessons follow a 3-month cycle. Difficulty increases each month.',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 14 : 20),
              // 3つのカード - モバイルでは縦並び
              if (isMobile)
                Column(
                  children: [
                    _buildCycleCardMobile(
                      cycleMonth: 1,
                      currentCycleMonth: currentCycleMonth,
                      emoji: '🌱',
                      isJa: isJa,
                    ),
                    const SizedBox(height: 10),
                    _buildCycleCardMobile(
                      cycleMonth: 2,
                      currentCycleMonth: currentCycleMonth,
                      emoji: '📖',
                      isJa: isJa,
                    ),
                    const SizedBox(height: 10),
                    _buildCycleCardMobile(
                      cycleMonth: 3,
                      currentCycleMonth: currentCycleMonth,
                      emoji: '🏃',
                      isJa: isJa,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    _buildCycleCard(
                      cycleMonth: 1,
                      currentCycleMonth: currentCycleMonth,
                      emoji: '🌱',
                      isJa: isJa,
                    ),
                    const SizedBox(width: 12),
                    _buildCycleCard(
                      cycleMonth: 2,
                      currentCycleMonth: currentCycleMonth,
                      emoji: '📖',
                      isJa: isJa,
                    ),
                    const SizedBox(width: 12),
                    _buildCycleCard(
                      cycleMonth: 3,
                      currentCycleMonth: currentCycleMonth,
                      emoji: '🏃',
                      isJa: isJa,
                    ),
                  ],
                ),
              SizedBox(height: isMobile ? 14 : 20),
              // 初心者向け注意
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9800).withOpacity(0.2),
                      const Color(0xFFFF9800).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: isMobile ? 20 : 24)),
                    SizedBox(width: isMobile ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isJa ? '初めての方へ' : 'For Beginners',
                            style: TextStyle(
                              color: const Color(0xFFe65100),
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 13 : 15,
                            ),
                          ),
                          SizedBox(height: isMobile ? 4 : 8),
                          Text(
                            isJa
                                ? '難しい月（3ヶ月目）に初めて参加される場合は、1つ下の学年のレッスンへの参加をおすすめします。'
                                : 'If this is your first time and it\'s an advanced month (Month 3), we recommend joining one grade level below.',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: isMobile ? 12 : 14,
                              height: 1.6,
                            ),
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
      },
    );
  }

  // モバイル用の横長カード
  Widget _buildCycleCardMobile({
    required int cycleMonth,
    required int currentCycleMonth,
    required String emoji,
    required bool isJa,
  }) {
    final isCurrentMonth = cycleMonth == currentCycleMonth;
    final color = _getCycleMonthColor(cycleMonth);
    final months = _getMonthsForCycle(cycleMonth, isJa);
    final textColor = cycleMonth == 1 ? const Color(0xFF166534) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color, color.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentMonth
            ? Border.all(color: const Color(0xFFffeb3b), width: 4)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isJa ? '${cycleMonth}ヶ月目' : 'Month $cycleMonth',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCycleMonthLabel(cycleMonth),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  months,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentMonth)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFffeb3b),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isJa ? '今月' : 'NOW',
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCycleCard({
    required int cycleMonth,
    required int currentCycleMonth,
    required String emoji,
    required bool isJa,
  }) {
    final isCurrentMonth = cycleMonth == currentCycleMonth;
    final color = _getCycleMonthColor(cycleMonth);
    final months = _getMonthsForCycle(cycleMonth, isJa);
    // 緑は薄いのでテキストを濃くする
    final textColor = cycleMonth == 1 ? const Color(0xFF166534) : Colors.white;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.85)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: isCurrentMonth
              ? Border.all(color: const Color(0xFFffeb3b), width: 4)
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              isJa ? '${cycleMonth}ヶ月目' : 'Month $cycleMonth',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getCycleMonthLabel(cycleMonth),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              months,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCurrentMonth) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFffeb3b),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isJa ? '今月' : 'NOW',
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getMonthsForCycle(int cycleMonth, bool isJa) {
    switch (cycleMonth) {
      case 1:
        return isJa ? '1,4,7,10月' : 'Jan,Apr,Jul,Oct';
      case 2:
        return isJa ? '2,5,8,11月' : 'Feb,May,Aug,Nov';
      case 3:
        return isJa ? '3,6,9,12月' : 'Mar,Jun,Sep,Dec';
      default:
        return '';
    }
  }
}
