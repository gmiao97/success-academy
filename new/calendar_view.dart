import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/calendar/calendar_utils.dart';
import 'package:success_academy/calendar/data/event_model.dart';
import 'package:success_academy/calendar/data/events_data_source.dart';
import 'package:success_academy/calendar/widgets/cancel_event_dialog.dart';
import 'package:success_academy/calendar/widgets/create_event_dialog.dart';
import 'package:success_academy/calendar/widgets/curriculum_cycle_notice.dart';
import 'package:success_academy/calendar/widgets/delete_event_dialog.dart';
import 'package:success_academy/calendar/widgets/edit_event_dialog.dart';
import 'package:success_academy/calendar/widgets/signup_event_dialog.dart';
import 'package:success_academy/calendar/widgets/view_event_dialog.dart';
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/helpers/tz_date_time.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest_10y.dart' as tz show initializeTimeZones;
import 'package:timezone/timezone.dart' as tz show getLocation;
import 'package:timezone/timezone.dart' show Location, TZDateTime;

// ============================================
// モダン＆クリーン（青×パープル）
// ============================================
class AppColors {
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryDark = Color(0xFF7C3AED);
  static const Color accent = Color(0xFF8B5CF6);  // パープルに統一
  static const Color success = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
}

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => EventsDataSource(),
        child: _CalendarView(),
      );
}

class _CalendarView extends StatefulWidget {
  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView>
    with SingleTickerProviderStateMixin {
  late final List<EventType> _availableEventTypes;
  late final DateTime _firstDay;
  late final DateTime _lastDay;
  late final Location _location;

  late EventsDataSource _eventsDataSource;
  late TZDateTime _currentDay;
  late TZDateTime _focusedDay;
  late TZDateTime _selectedDay;
  late List<EventType> _selectedEventTypes;

  final Set<EventModel> _allEvents = {};
  List<EventModel> _selectedEvents = [];
  Map<DateTime, List<EventModel>> _displayedEvents = {};
  EventDisplay _eventDisplay = EventDisplay.all;
  bool _isLoading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    final account = context.read<AccountModel>();
    _location = tz.getLocation(account.myUser!.timeZone);
    _currentDay = _focusedDay = _selectedDay = _getCurrentDate();
    _firstDay = _currentDay.subtract(const Duration(days: 1000));
    _lastDay = _currentDay.add(const Duration(days: 1000));
    _availableEventTypes = _selectedEventTypes =
        getEventTypesCanView(account.userType, account.subscriptionPlan);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    _eventsDataSource = context.watch<EventsDataSource>();
    _onPageChanged(_focusedDay);
  }

  Future<void> _loadEvents(TZDateTimeRange dateTimeRange) async {
    setState(() {
      _isLoading = true;
    });

    _allEvents
      ..clear()
      ..addAll(
        await _eventsDataSource.loadDataByKey(
          dateTimeRange,
        ),
      );

    setState(() {
      _displayedEvents = _getFilteredEvents();
      _selectedEvents = _getEventsForDay(_selectedDay);
      _isLoading = false;
    });
  }

  Map<DateTime, List<EventModel>> _getFilteredEvents() {
    final account = context.read<AccountModel>();
    return buildEventMap(
      _allEvents.where((event) {
        if (!_selectedEventTypes.contains(event.eventType)) {
          return false;
        }
        if (_eventDisplay == EventDisplay.mine) {
          if (account.userType == UserType.teacher) {
            return isTeacherInEvent(account.teacherProfile!.profileId, event);
          }
          if (account.userType == UserType.student) {
            return isStudentInEvent(account.studentProfile!.profileId, event);
          }
        }
        return true;
      }).toList(),
    );
  }

  List<EventModel> _getEventsForDay(DateTime day) =>
      _displayedEvents[DateUtils.dateOnly(day)] ?? [];

  // 「専用」レッスンかどうかを判定
  bool _isPrivateLesson(EventModel event) {
    if (event.eventType == EventType.preschool) return false;
    return event.eventType == EventType.private ||
        event.summary.contains('専用');
  }

  // フリーレッスンを取得（preschoolを含む、専用を除く）
  List<EventModel> _getFreeEvents() {
    return _selectedEvents.where((e) {
      if (_isPrivateLesson(e)) return false;
      return e.eventType == EventType.free ||
          e.eventType == EventType.preschool;
    }).toList();
  }

  // 個別レッスンを取得（専用を含む）
  List<EventModel> _getPrivateEvents() {
    return _selectedEvents.where((e) => _isPrivateLesson(e)).toList();
  }

  void _onTodayButtonClick() {
    setState(() {
      _focusedDay = _selectedDay = _currentDay = _getCurrentDate();
      _selectedEvents = _getEventsForDay(_selectedDay);
    });
  }

  void _onEventFiltersChanged(
    List<EventType> eventTypes,
    EventDisplay eventDisplay,
  ) {
    setState(() {
      _selectedEventTypes = eventTypes;
      _eventDisplay = eventDisplay;
      _displayedEvents = _getFilteredEvents();
      _selectedEvents = _getEventsForDay(_selectedDay);
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = TZDateTime(
        _location,
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      _focusedDay = TZDateTime(
        _location,
        focusedDay.year,
        focusedDay.month,
        focusedDay.day,
      );
      _selectedEvents = _getEventsForDay(_selectedDay);
    });
  }

  Future<void> _onPageChanged(DateTime focusedDay) async {
    setState(() {
      _focusedDay = _selectedDay = TZDateTime(
        _location,
        focusedDay.year,
        focusedDay.month,
        focusedDay.day,
      );
    });

    await _loadEvents(
      TZDateTimeRange(
        start: _focusedDay.mostRecentWeekday(0),
        end: _focusedDay.mostRecentWeekday(0).add(const Duration(days: 7)),
      ),
    );

    final cachedDateTimeRange = _eventsDataSource.cachedDateTimeRanges[0];
    if (_focusedDay
        .subtract(const Duration(days: 10))
        .isBefore(cachedDateTimeRange.start)) {
      _eventsDataSource.fetchAndStoreDataByKey(
        TZDateTimeRange(
          start: _focusedDay.subtract(const Duration(days: 50)),
          end: _eventsDataSource.cachedDateTimeRanges[0].end,
        ),
      );
    }
    if (_focusedDay
        .add(const Duration(days: 10))
        .isAfter(cachedDateTimeRange.end)) {
      _eventsDataSource.fetchAndStoreDataByKey(
        TZDateTimeRange(
          start: cachedDateTimeRange.start,
          end: _focusedDay.add(const Duration(days: 50)),
        ),
      );
    }
  }

  TZDateTime _getCurrentDate() => TZDateTime.from(
        DateUtils.dateOnly(
          TZDateTime.now(
            _location,
          ),
        ),
        _location,
      );

  Future<void> _onCreateEvent(EventModel event) async {
    if (event.recurrence.isEmpty) {
      _eventsDataSource.storeEvent(event);
    } else {
      await _eventsDataSource.storeInstances(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AccountModel, String>((a) => a.locale);
    final userType = context.select<AccountModel, UserType>((a) => a.userType);
    final teacherId = context
        .select<AccountModel, String?>((a) => a.teacherProfile?.profileId);
    final isJapanese = locale.startsWith('ja');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            Colors.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isLoading)
                        LinearProgressIndicator(
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        )
                      else
                        const SizedBox(height: 4),

                      // タイムゾーン表示
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              context
                                  .read<AccountModel>()
                                  .myUser!
                                  .timeZone
                                  .replaceAll('_', '/'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

          // カレンダー
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TableCalendar(
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.chevron_left, color: AppColors.primary),
                  ),
                  rightChevronIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.chevron_right, color: AppColors.primary),
                  ),
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  todayTextStyle: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  markerSize: 6,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                ),
                calendarBuilders: CalendarBuilders(
                  headerTitleBuilder: (context, day) => _CalendarHeader(
                    day: day,
                    availableEventTypes: _availableEventTypes,
                    selectedEventTypes: _selectedEventTypes,
                    eventDisplay: _eventDisplay,
                    onTodayButtonClick: _onTodayButtonClick,
                    onEventFiltersChanged: _onEventFiltersChanged,
                  ),
                ),
                calendarFormat: CalendarFormat.week,
                daysOfWeekHeight: 24,
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  weekendStyle: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                locale: locale,
                currentDay: _currentDay,
                focusedDay: _focusedDay,
                firstDay: _firstDay,
                lastDay: _lastDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: _onDaySelected,
                onPageChanged: _onPageChanged,
                eventLoader: _getEventsForDay,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 3ヶ月1クール制の注意書き
          CurriculumCycleNotice(locale: locale),

          const SizedBox(height: 8),

          // タブ
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎓'),
                      const SizedBox(width: 6),
                      Text(isJapanese ? 'フリーレッスン' : 'Free Lessons'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👤'),
                      const SizedBox(width: 6),
                      Text(isJapanese ? '個別レッスン' : 'Private Lesson'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // フリーレッスンタブ
                _FreeEventList(
                  events: _getFreeEvents(),
                  firstDay: _firstDay,
                  lastDay: _lastDay,
                  refreshState: () => setState(() {}),
                  onDeleteEvent: _eventsDataSource.removeEvent,
                  locale: locale,
                ),
                // 個別レッスンタブ
                _PrivateEventList(
                  events: _getPrivateEvents(),
                  firstDay: _firstDay,
                  lastDay: _lastDay,
                  refreshState: () => setState(() {}),
                  onDeleteEvent: _eventsDataSource.removeEvent,
                  locale: locale,
                ),
              ],
            ),
          ),
          // FABを右下に固定
          if (canEditEvents(userType))
            Positioned(
              right: kFloatingActionButtonMargin,
              bottom: kFloatingActionButtonMargin,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => CreateEventDialog(
                      teacherId: teacherId,
                      firstDay: _firstDay,
                      lastDay: _lastDay,
                      selectedDay: _selectedDay,
                      onCreateEvent: _onCreateEvent,
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    S.of(context).createEvent,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

class _CalendarHeader extends StatefulWidget {
  final DateTime day;
  final List<EventType> availableEventTypes;
  final List<EventType> selectedEventTypes;
  final EventDisplay eventDisplay;
  final VoidCallback onTodayButtonClick;
  final void Function(List<EventType>, EventDisplay) onEventFiltersChanged;

  const _CalendarHeader({
    required this.day,
    required this.availableEventTypes,
    required this.selectedEventTypes,
    required this.eventDisplay,
    required this.onTodayButtonClick,
    required this.onEventFiltersChanged,
  });

  @override
  State<_CalendarHeader> createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends State<_CalendarHeader> {
  late EventDisplay _eventDisplay;

  @override
  void initState() {
    super.initState();
    _eventDisplay = widget.eventDisplay;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AccountModel, String>((a) => a.locale);
    final isJapanese = locale.startsWith('ja');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 360;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // フィルターボタン
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.secondary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: 8,
                ),
              ),
              icon: Icon(Icons.filter_list, color: AppColors.secondary, size: isMobile ? 16 : 18),
              label: Text(
                isMobile ? '' : (isJapanese ? 'フィルター' : 'Filter'),
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              onPressed: () => showModalBottomSheet(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) => SizedBox(
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        S.of(context).filter,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Column(
                        children: [
                          RadioListTile<EventDisplay>(
                            title: Text(EventDisplay.all.getName(context)),
                            value: EventDisplay.all,
                            groupValue: _eventDisplay,
                            onChanged: (value) {
                              setState(() {
                                _eventDisplay = value!;
                              });
                            },
                          ),
                          RadioListTile<EventDisplay>(
                            title: Text(EventDisplay.mine.getName(context)),
                            value: EventDisplay.mine,
                            groupValue: _eventDisplay,
                            onChanged: (value) {
                              setState(() {
                                _eventDisplay = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: MultiSelectBottomSheet<EventType>(
                          items: widget.availableEventTypes
                              .map(
                                (e) => MultiSelectItem(e, e.getName(context)),
                              )
                              .toList(),
                          initialValue: widget.selectedEventTypes,
                          title: Text(
                            S.of(context).eventType,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          listType: MultiSelectListType.CHIP,
                          confirmText: Text(S.of(context).confirm),
                          cancelText: Text(S.of(context).cancel),
                          initialChildSize: 1.0,
                          maxChildSize: 1.0,
                          onConfirm: (values) {
                            widget.onEventFiltersChanged(
                              values,
                              _eventDisplay,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 月表示
        Text(
          DateFormat.yMMM(locale).format(widget.day),
          style: TextStyle(
            fontSize: isMobile ? 14 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        // 今日ボタン
        TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: AppColors.warning.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: 8,
            ),
          ),
          icon: Icon(Icons.today, color: AppColors.warning, size: isMobile ? 16 : 18),
          label: Text(
            isMobile ? '' : (isJapanese ? '今日' : 'Today'),
            style: TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          onPressed: widget.onTodayButtonClick,
        ),
      ],
    );
    },
    );
  }
}

// フリーレッスンリスト
class _FreeEventList extends StatelessWidget {
  final List<EventModel> events;
  final DateTime firstDay;
  final DateTime lastDay;
  final VoidCallback refreshState;
  final OnDeleteEventCallback onDeleteEvent;
  final String locale;

  const _FreeEventList({
    required this.events,
    required this.firstDay,
    required this.lastDay,
    required this.refreshState,
    required this.onDeleteEvent,
    required this.locale,
  });

  Map<String, List<EventModel>> _groupEventsBySummary() {
    final Map<String, List<EventModel>> grouped = {};
    for (final event in events) {
      if (!grouped.containsKey(event.summary)) {
        grouped[event.summary] = [];
      }
      grouped[event.summary]!.add(event);
    }
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isJapanese = locale.startsWith('ja');
    final emptyMessage = isJapanese
        ? 'フリーレッスンがありません'
        : 'No free lessons available';

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final groupedEvents = _groupEventsBySummary();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 8),
      itemCount: groupedEvents.length,
      itemBuilder: (context, index) {
        final summary = groupedEvents.keys.elementAt(index);
        final eventList = groupedEvents[summary]!;
        final firstEvent = eventList.first;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          firstEvent.eventType == EventType.preschool
                              ? '📚'
                              : '📚',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            firstEvent.eventType.getName(context),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 時間チップ
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: eventList.map((event) {
                    return _TimeSlotChip(
                      event: event,
                      locale: locale,
                      refreshState: refreshState,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 時間チップ
class _TimeSlotChip extends StatelessWidget {
  final EventModel event;
  final String locale;
  final VoidCallback refreshState;

  const _TimeSlotChip({
    required this.event,
    required this.locale,
    required this.refreshState,
  });

  @override
  Widget build(BuildContext context) {
    final account = context.read<AccountModel>();
    final isSignedUp = account.userType == UserType.student &&
        isStudentInEvent(account.studentProfile!.profileId, event);
    final isFull = isEventFull(event);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog(
          context: context,
          builder: (context) => ViewEventDialog(
            event: event,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSignedUp
                ? AppColors.success.withOpacity(0.15)
                : isFull
                    ? Colors.grey[200]
                    : AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSignedUp
                  ? AppColors.success
                  : isFull
                      ? Colors.grey[400]!
                      : AppColors.secondary,
              width: isSignedUp ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSignedUp)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.check_circle,
                      color: AppColors.success, size: 18),
                ),
              Text(
                DateFormat.Hm(locale).format(event.startTime),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSignedUp
                      ? AppColors.success
                      : isFull
                          ? Colors.grey[600]
                          : AppColors.secondary,
                ),
              ),
              if (isFull && !isSignedUp)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    locale.startsWith('ja') ? '満席' : 'Full',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 個別レッスンリスト
class _PrivateEventList extends StatelessWidget {
  final List<EventModel> events;
  final DateTime firstDay;
  final DateTime lastDay;
  final VoidCallback refreshState;
  final OnDeleteEventCallback onDeleteEvent;
  final String locale;

  const _PrivateEventList({
    required this.events,
    required this.firstDay,
    required this.lastDay,
    required this.refreshState,
    required this.onDeleteEvent,
    required this.locale,
  });

  Widget _getEventActions(BuildContext context, EventModel event) {
    final account = context.read<AccountModel>();

    if (account.userType == UserType.student) {
      if (isStudentInEvent(account.studentProfile!.profileId, event)) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton.icon(
            icon: Icon(Icons.check, color: AppColors.success, size: 18),
            label: Text(
              S.of(context).signedUp,
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => CancelEventDialog(
                event: event,
                refresh: refreshState,
              ),
            ),
          ),
        );
      } else if (isEventFull(event)) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            S.of(context).eventFull,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.secondary, AppColors.secondaryDark],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              S.of(context).signup,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => SignupEventDialog(
                event: event,
                refresh: refreshState,
              ),
            ),
          ),
        );
      }
    }
    if (account.userType == UserType.teacher) {
      if (isTeacherInEvent(account.teacherProfile!.profileId, event)) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.edit, color: AppColors.primary),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => EditEventDialog(
                    event: event,
                    firstDay: firstDay,
                    lastDay: lastDay,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.delete, color: AppColors.danger),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => DeleteEventDialog(
                    event: event,
                    onDeleteEvent: onDeleteEvent,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }
    if (account.userType == UserType.admin) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.edit, color: AppColors.primary),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => EditEventDialog(
                  event: event,
                  firstDay: firstDay,
                  lastDay: lastDay,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.delete, color: AppColors.danger),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => DeleteEventDialog(
                  event: event,
                  onDeleteEvent: onDeleteEvent,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isJapanese = locale.startsWith('ja');
    final emptyMessage = isJapanese
        ? '個別レッスンがありません'
        : 'No private lessons available';

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showDialog(
                context: context,
                builder: (context) => ViewEventDialog(event: event),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('👤', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.summary,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  event.eventType.getName(context),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '🕐 ${DateFormat.jm(locale).format(event.startTime)} - ${DateFormat.jm(locale).format(event.endTime)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _getEventActions(context, event),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
