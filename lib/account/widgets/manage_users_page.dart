import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/calendar/calendar_utils.dart';
import 'package:success_academy/calendar/data/event_model.dart';
import 'package:success_academy/calendar/data/events_data_source.dart';
import 'package:success_academy/constants.dart';
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/helpers/tz_date_time.dart';
import 'package:success_academy/profile/data/profile_model.dart';
import 'package:success_academy/profile/services/profile_service.dart'
    as profile_service;
import 'package:timezone/data/latest_10y.dart' as tz show initializeTimeZones;
import 'package:timezone/timezone.dart' as tz show getLocation;
import 'package:timezone/timezone.dart' show TZDateTime;

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => EventsDataSource(),
        child: _ManageUsersPage(),
      );
}

class _ManageUsersPage extends StatefulWidget {
  @override
  State<_ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<_ManageUsersPage> {
  late final EventsDataSource _eventsDataSource;
  final List<bool> _selectedToggle = [true, false];
  final List<EventModel> _events = [];
  late TZDateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    final location =
        tz.getLocation(context.read<AccountModel>().myUser!.timeZone);
    _eventsDataSource = context.watch<EventsDataSource>();
    _dateRange = TZDateTimeRange(
      start: TZDateTime.now(location).subtract(const Duration(days: 30)),
      end: TZDateTime.now(location),
    );
    _events.addAll(
      await _eventsDataSource.loadDataByKey(
        _dateRange,
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final location =
        tz.getLocation(context.read<AccountModel>().myUser!.timeZone);

    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: TZDateTime(location, 2020, 1, 1),
      lastDate: TZDateTime.now(location),
    );
    if (dateRange != null) {
      final start = TZDateTime.from(dateRange.start, location);
      final end = TZDateTime.from(dateRange.end, location);
      final events = await _eventsDataSource.loadDataByKey(
        TZDateTimeRange(
          start: start,
          end: end,
        ),
      );
      setState(
        () {
          _dateRange = TZDateTimeRange(start: start, end: end);
          _events
            ..clear()
            ..addAll(events);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  S.of(context).manageProfile,
                  style: Theme.of(context).textTheme.displaySmall,
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
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    minWidth: 80,
                  ),
                  isSelected: _selectedToggle,
                  children: [
                    Text(S.of(context).student),
                    Text(S.of(context).teacher),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _selectedToggle[0]
                      ? _StudentTable()
                      : _TeacherTable(
                          dateRange: _dateRange,
                          onSelectDateRange: _selectDateRange,
                          events: _events,
                        ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _TeacherTable extends StatelessWidget {
  final DateTimeRange dateRange;
  final VoidCallback onSelectDateRange;
  final List<EventModel> events;

  const _TeacherTable({
    required this.dateRange,
    required this.onSelectDateRange,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final teacherProfiles =
        context.select<AccountModel, List<TeacherProfileModel>>(
      (a) => a.teacherProfileList,
    );

    return PaginatedDataTable(
      header: TextButton.icon(
        icon: const Icon(Icons.edit),
        label: Text(
          '${dateFormatter.format(dateRange.start)} - ${dateFormatter.format(dateRange.end)}',
        ),
        onPressed: onSelectDateRange,
      ),
      columns: <DataColumn>[
        DataColumn(
          label: Expanded(
            child: Text(
              S.of(context).id,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              S.of(context).email,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              S.of(context).lastName,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              S.of(context).firstName,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              S.of(context).freeNum,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              S.of(context).preschoolNum,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              S.of(context).privateNum,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ],
      source: _TeacherData(
        context: context,
        data: teacherProfiles,
        events: events,
      ),
    );
  }
}

class _StudentTable extends StatefulWidget {
  @override
  State<_StudentTable> createState() => _StudentTableState();
}

class _StudentTableState extends State<_StudentTable> {
  final List<StudentProfileModel> _studentProfiles = [];
  String? _searchEmail;

  @override
  void initState() {
    super.initState();
    _loadStudentProfiles();
  }

  Future<void> _loadStudentProfiles() async {
    _studentProfiles.addAll(
      await profile_service.getAllStudentProfiles(),
    );
  }

  Iterable<Widget> _getSuggestions(SearchController controller) {
    if (controller.text.isEmpty) {
      return _studentProfiles.map(
        (e) => ListTile(
          title: Text(e.email),
          onTap: () {
            controller.closeView(e.email);
            setState(() {
              _searchEmail = e.email;
            });
          },
        ),
      );
    }
    return _studentProfiles
        .where(
          (e) => e.email.toLowerCase().contains(controller.text.toLowerCase()),
        )
        .map(
          (e) => ListTile(
            title: Text(e.email),
            onTap: () {
              controller.closeView(e.email);
              setState(() {
                _searchEmail = e.email;
              });
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SearchAnchor(
            builder: (context, controller) => SearchBar(
              controller: controller,
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),
              hintText: S.of(context).searchEmail,
              trailing: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    setState(() {
                      _searchEmail = null;
                    });
                  },
                ),
              ],
              onTap: () {
                controller.openView();
              },
              onChanged: (_) {
                controller.openView();
              },
              leading: const Icon(Icons.search),
            ),
            viewHintText: S.of(context).searchEmail,
            viewTrailing: const [],
            suggestionsBuilder: (context, controller) =>
                _getSuggestions(controller),
          ),
          PaginatedDataTable(
            columns: <DataColumn>[
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).id,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).email,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).lastName,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).firstName,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).eventPointsLabel,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).referrerLabel,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ],
            source: _StudentData(
              data: _searchEmail?.isEmpty ?? true
                  ? _studentProfiles
                  : _studentProfiles
                      .where((e) => e.email == _searchEmail)
                      .toList(),
            ),
          ),
        ],
      );
}

class _TeacherData extends DataTableSource {
  _TeacherData({
    required BuildContext context,
    required List<TeacherProfileModel> data,
    required List<EventModel> events,
  })  : _context = context,
        _data = data,
        _events = events;

  final BuildContext _context;
  final List<TeacherProfileModel> _data;
  final List<EventModel> _events;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;

  @override
  DataRow getRow(int index) {
    final account = _context.read<AccountModel>();

    final completedPrivateEvents = _events
        .where(
          (e) =>
              e.eventType == EventType.private &&
              isTeacherInEvent(_data[index].profileId, e) &&
              e.studentIdList.isNotEmpty,
        )
        .toList();

    return DataRow(
      cells: [
        DataCell(SelectableText(_data[index].profileId)),
        DataCell(SelectableText(_data[index].email)),
        DataCell(SelectableText(_data[index].lastName)),
        DataCell(SelectableText(_data[index].firstName)),
        DataCell(
          SelectableText(
            '${_events.where((e) => e.eventType == EventType.free && isTeacherInEvent(_data[index].profileId, e)).length}',
          ),
        ),
        DataCell(
          SelectableText(
            '${_events.where((e) => e.eventType == EventType.preschool && isTeacherInEvent(_data[index].profileId, e)).length}',
          ),
        ),
        DataCell(
          SelectableText(
            '${completedPrivateEvents.map((event) => event.numPoints).fold(0, (int a, int b) => a + b)}',
          ),
          onTap: () => showDialog(
            context: _context,
            builder: (context) => AlertDialog(
              content: SizedBox(
                width: 500,
                height: 500,
                child: ListView(
                  children: completedPrivateEvents
                      .map(
                        (event) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(event.summary),
                            Text(
                              DateFormat.yMd(account.locale)
                                  .add_jm()
                                  .format(event.startTime),
                            ),
                            Text('${event.numPoints}'),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentData extends DataTableSource {
  final List<StudentProfileModel> _data;

  _StudentData({
    required List<StudentProfileModel> data,
  }) : _data = data;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;

  @override
  DataRow getRow(int index) => DataRow(
        cells: [
          DataCell(SelectableText(_data[index].profileId)),
          DataCell(SelectableText(_data[index].email)),
          DataCell(SelectableText(_data[index].lastName)),
          DataCell(SelectableText(_data[index].firstName)),
          DataCell(SelectableText('${_data[index].numPoints}')),
          DataCell(SelectableText(_data[index].referrer ?? '')),
        ],
      );
}
