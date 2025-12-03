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

class _CalendarViewState extends State<_CalendarView> {
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

    // Display events for currently visible date range.
    await _loadEvents(
      TZDateTimeRange(
        start: _focusedDay.mostRecentWeekday(0),
        end: _focusedDay.mostRecentWeekday(0).add(const Duration(days: 7)),
      ),
    );

    // Prefetch the next pages of data.
    // The calendar events data source contains a single continuous date time
    // range.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoading)
          LinearProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.surface,
          )
        else
          const SizedBox(height: 4),
        Card(
          child: TableCalendar(
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              leftChevronPadding: EdgeInsets.all(8),
              rightChevronPadding: EdgeInsets.all(8),
              leftChevronMargin: EdgeInsets.symmetric(horizontal: 4),
              rightChevronMargin: EdgeInsets.symmetric(horizontal: 4),
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
            daysOfWeekHeight: 20,
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
        Center(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              DateFormat.yMMMMEEEEd(locale).format(_selectedDay),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              _EventList(
                events: _selectedEvents,
                firstDay: _firstDay,
                lastDay: _lastDay,
                refreshState: () {
                  setState(() {});
                },
                onDeleteEvent: _eventsDataSource.removeEvent,
              ),
              if (canEditEvents(userType))
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(kFloatingActionButtonMargin),
                    child: FloatingActionButton.extended(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
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
                      icon: const Icon(Icons.add),
                      label: Text(
                        S.of(context).createEvent,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
  // Track local copy of event display radio and set calendar's event display
  // state together with event types when confirm is clicked.
  late EventDisplay _eventDisplay;

  @override
  void initState() {
    super.initState();
    _eventDisplay = widget.eventDisplay;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AccountModel, String>((a) => a.locale);
    final timeZone =
        context.select<AccountModel, String>((a) => a.myUser!.timeZone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat.yMMM(locale).format(widget.day),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Text(S.of(context).lessonSignupWarning),
            Text(
              timeZone.replaceAll('_', ' '),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.filter_list),
              label: Text(S.of(context).filter),
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
                                    (e) =>
                                        MultiSelectItem(e, e.getName(context)),
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
            TextButton.icon(
              icon: Text(S.of(context).today),
              label: const Icon(Icons.today),
              onPressed: widget.onTodayButtonClick,
            ),
          ],
        ),
      ],
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.events,
    required this.firstDay,
    required this.lastDay,
    required this.refreshState,
    required this.onDeleteEvent,
  });

  final List<EventModel> events;
  final DateTime firstDay;
  final DateTime lastDay;
  final VoidCallback refreshState;
  final OnDeleteEventCallback onDeleteEvent;

  Widget _getEventActions(BuildContext context, EventModel event) {
    final account = context.read<AccountModel>();

    if (account.userType == UserType.student) {
      if (isStudentInEvent(account.studentProfile!.profileId, event)) {
        return FilledButton.tonalIcon(
          icon: const Icon(Icons.check),
          label: Text(S.of(context).signedUp),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => CancelEventDialog(
              event: event,
              refresh: refreshState,
            ),
          ),
        );
      } else if (isEventFull(event)) {
        return OutlinedButton(
          onPressed: null,
          child: Text(S.of(context).eventFull),
        );
      } else {
        return OutlinedButton(
          child: Text(S.of(context).signup),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => SignupEventDialog(
              event: event,
              refresh: refreshState,
            ),
          ),
        );
      }
    }
    if (account.userType == UserType.teacher) {
      if (isTeacherInEvent(account.teacherProfile!.profileId, event)) {
        return SizedBox(
          width: 80,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => EditEventDialog(
                    event: event,
                    firstDay: firstDay,
                    lastDay: lastDay,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => DeleteEventDialog(
                    event: event,
                    onDeleteEvent: onDeleteEvent,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    if (account.userType == UserType.admin) {
      return SizedBox(
        width: 80,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => EditEventDialog(
                  event: event,
                  firstDay: firstDay,
                  lastDay: lastDay,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => DeleteEventDialog(
                  event: event,
                  onDeleteEvent: onDeleteEvent,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AccountModel, String>((a) => a.locale);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: events.length,
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Card(
            elevation: 4,
            color: events[index].eventType.getColor(context),
            child: ListTile(
              leading: events[index].eventType.getIcon(context),
              trailing: _getEventActions(context, events[index]),
              title: Text(
                events[index].summary,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    events[index].eventType.getName(context),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                  Text(
                    '${DateFormat.jm(locale).format(events[index].startTime)} - ${DateFormat.jm(locale).format(events[index].endTime)}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              onTap: () => showDialog(
                context: context,
                builder: (context) => ViewEventDialog(
                  event: events[index],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
