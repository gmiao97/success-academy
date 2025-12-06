import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rrule/rrule.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/calendar/data/event_model.dart';
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/profile/data/profile_model.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

String frequencyToString(BuildContext context, Frequency frequency) {
  if (frequency == Frequency.daily) {
    return S.of(context).recurDaily;
  }
  if (frequency == Frequency.weekly) {
    return S.of(context).recurWeekly;
  }
  if (frequency == Frequency.monthly) {
    return S.of(context).recurMonthly;
  }
  return '¯\\_(ツ)_/¯';
}

String rruleToString(BuildContext context, RecurrenceRule? rrule) {
  if (rrule == null) {
    return S.of(context).recurNone;
  }

  final locale = context.select<AccountModel, String>((a) => a.locale);

  final buffer = StringBuffer(frequencyToString(context, rrule.frequency));
  final until = rrule.until;
  if (until != null) {
    buffer.write(
      S.of(context).recurUntil(DateFormat.yMMMMd(locale).format(rrule.until!)),
    );
  }
  return buffer.toString();
}

List<String> buildRecurrence({
  required Frequency frequency,
  TZDateTime? until,
}) =>
    [
      RecurrenceRule(frequency: frequency, until: until?.toUtc()).toString(
        options: const RecurrenceRuleToStringOptions(isTimeUtc: true),
      ),
    ];

bool canEditEvents(UserType userType) =>
    userType == UserType.admin || userType == UserType.teacher;

List<EventType> getEventTypesCanEdit(UserType userType) {
  switch (userType) {
    case UserType.admin:
      return [EventType.free, EventType.preschool, EventType.private];
    case UserType.teacher:
      return [EventType.private];
    default:
      return [];
  }
}

List<EventType> getEventTypesCanView(
  UserType userType,
  SubscriptionPlan? subscription,
) {
  if ([UserType.admin, UserType.teacher].contains(userType)) {
    return [
      EventType.free,
      EventType.preschool,
      EventType.private,
    ];
  }
  if (userType == UserType.student) {
    if (subscription == null) {
      return [];
    }
    if (subscription == SubscriptionPlan.monthly) {
      return [
        EventType.private,
      ];
    }
    if (subscription == SubscriptionPlan.minimumPreschool) {
      return [
        EventType.free,
        EventType.preschool,
        EventType.private,
      ];
    }
    if (subscription == SubscriptionPlan.minimum) {
      return [
        EventType.free,
        EventType.private,
      ];
    }
  }
  return [];
}

bool isStudentInEvent(String profileId, EventModel event) =>
    event.studentIdList.contains(profileId);

bool isEventFull(EventModel event) {
  if (event.eventType == EventType.private && event.studentIdList.isNotEmpty) {
    return true;
  }
  return false;
}

bool isTeacherInEvent(String profileId, EventModel event) =>
    event.teacherId == profileId;
