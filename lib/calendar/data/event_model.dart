import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rrule/rrule.dart';
import 'package:success_academy/generated/l10n.dart';
import 'package:timezone/timezone.dart' show Location, TZDateTime;

enum EventType {
  unknown,
  free,
  preschool,
  private;

  String getName(BuildContext context) {
    switch (this) {
      case unknown:
        return '¯\\_(ツ)_/¯';
      case free:
        return S.of(context).free;
      case preschool:
        return S.of(context).preschool;
      case private:
        return S.of(context).private;
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case unknown:
        return Colors.grey[100]!;
      case free:
        return Colors.amber[100]!;
      case preschool:
        return Colors.lightBlue[100]!;
      case private:
        return Colors.purple[100]!;
    }
  }

  Icon getIcon(BuildContext context) {
    switch (this) {
      case unknown:
        return const Icon(FontAwesomeIcons.question);
      case free:
        return const Icon(FontAwesomeIcons.personChalkboard);
      case preschool:
        return const Icon(FontAwesomeIcons.shapes);
      case private:
        return const Icon(FontAwesomeIcons.graduationCap);
    }
  }
}

enum EventDisplay {
  all,
  mine;

  String getName(BuildContext context) {
    switch (this) {
      case all:
        return S.of(context).allEvents;
      case mine:
        return S.of(context).myEvents;
    }
  }
}

List<Frequency> recurFrequencies = [
  Frequency.daily,
  Frequency.weekly,
  Frequency.monthly,
];

class EventModel {
  String? eventId;
  String? recurrenceId;
  String summary;
  String description;
  TZDateTime startTime;
  TZDateTime endTime;
  String timeZone;

  List<String> recurrence;
  String? teacherId;
  List<String> studentIdList = [];
  late int numPoints;
  EventType eventType = EventType.unknown;

  EventModel({
    this.eventId,
    required this.eventType,
    required this.summary,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.timeZone,
    this.recurrence = const [],
    this.teacherId,
    this.studentIdList = const [],
    required this.numPoints,
  });

  /// Build object from response returned by Google Calendar API.
  EventModel.fromJson(
    Map<String, Object?> json, {
    required Location location,
  })  : eventId = json['id'] as String,
        recurrenceId = json['recurringEventId'] as String?,
        summary = json['summary'] as String,
        description = json['description'] as String,
        startTime =
            TZDateTime.parse(location, (json['start'] as Map)['dateTime']),
        endTime = TZDateTime.parse(location, (json['end'] as Map)['dateTime']),
        recurrence = json['recurrence'] != null
            ? (json['recurrence'] as List<dynamic>)
                .map((e) => (e as String).replaceAll('WKST=SU', 'WKST=MO'))
                .toList()
            : [],
        timeZone = (json['start'] as Map)['timeZone'] as String {
    final extendedProperties =
        (json['extendedProperties'] as Map)['shared'] as Map<String, dynamic>;
    eventType = EnumToString.fromString(
          EventType.values,
          extendedProperties['eventType'],
        ) ??
        EventType.unknown;
    teacherId = extendedProperties['teacherId'];
    studentIdList = extendedProperties['studentIdList'] != null
        ? jsonDecode(extendedProperties['studentIdList']).cast<String>()
        : [];
    numPoints = int.tryParse(extendedProperties['numPoints'] ?? 'none') ?? 0;
  }

  Map<String, Object?> toJson() => {
        'eventId': eventId,
        'eventType': EnumToString.convertToString(eventType),
        'summary': summary,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'timeZone': timeZone,
        'recurrence': recurrence,
        'teacherId': teacherId,
        'studentIdList': studentIdList,
        'numPoints': numPoints,
      };

  @override
  bool operator ==(Object other) =>
      other is EventModel && eventId != null && other.eventId == eventId;

  @override
  int get hashCode => eventId.hashCode;
}

Map<DateTime, List<EventModel>> buildEventMap(Iterable<EventModel> eventList) {
  final eventMap = <DateTime, List<EventModel>>{};
  for (final event in eventList) {
    eventMap
        .putIfAbsent(DateUtils.dateOnly(event.startTime), () => [])
        .add(event);
  }
  eventMap.forEach((key, value) {
    value.sort(((a, b) => a.startTime.compareTo(b.startTime)));
  });
  return eventMap;
}
