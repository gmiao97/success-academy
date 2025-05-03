import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:success_academy/calendar/data/event_model.dart';
import 'package:success_academy/helpers/tz_date_time.dart';
import 'package:timezone/timezone.dart' show Location;

const isDev = false;

final Logger _logger = Logger();
final FirebaseFunctions _functions =
    FirebaseFunctions.instanceFor(region: 'us-west2');

Future<EventModel> getEvent({
  required String eventId,
  required Location location,
}) async {
  final callable = _functions.httpsCallable(
    'calendar_functions-get_event',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 60),
    ),
  );

  try {
    final result = await callable({
      'eventId': eventId,
      'isDev': isDev,
    });
    return EventModel.fromJson(result.data, location: location);
  } catch (err) {
    debugPrint('getEvent failed: $err');
    rethrow;
  }
}

Future<List<EventModel>> listEvents({
  required Location location,
  required TZDateTimeRange dateTimeRange,
  required bool singleEvents,
}) async {
  final callable = _functions.httpsCallable(
    'calendar_functions-list_events',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 60),
    ),
  );

  try {
    final result = await callable({
      'timeZone': location.name,
      'timeMin': dateTimeRange.start.toIso8601String(),
      'timeMax': dateTimeRange.end.toIso8601String(),
      'singleEvents': singleEvents,
      'isDev': isDev,
    });
    return (result.data as List<dynamic>)
        .where((e) => e['status'] != 'cancelled')
        .map((event) => EventModel.fromJson(event, location: location))
        .toList();
  } catch (err) {
    debugPrint('listEvents failed: $err');
    rethrow;
  }
}

Future<List<EventModel>> listInstances({
  required String eventId,
  required Location location,
  required TZDateTimeRange dateTimeRange,
}) async {
  final callable = _functions.httpsCallable(
    'calendar_functions-list_instances',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 60),
    ),
  );

  try {
    final result = await callable({
      'eventId': eventId,
      'timeZone': location.name,
      'timeMin': dateTimeRange.start.toIso8601String(),
      'timeMax': dateTimeRange.end.toIso8601String(),
      'isDev': isDev,
    });
    return (result.data as List<dynamic>)
        .where((e) => e['status'] != 'cancelled')
        .map((event) => EventModel.fromJson(event, location: location))
        .toList();
  } catch (e, s) {
    _logger.e(
      'listInstances failed',
      error: e,
      stackTrace: s,
    );
    rethrow;
  }
}

Future<dynamic> deleteEvent({
  required String eventId,
}) async {
  final callable = _functions.httpsCallable(
    'calendar_functions-delete_event',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 60),
    ),
  );

  try {
    final result = await callable({
      'eventId': eventId,
      'isDev': isDev,
    });
    return result.data;
  } catch (err) {
    debugPrint('deleteEvent failed: $err');
    rethrow;
  }
}

Future<dynamic> insertEvent(
  EventModel event, {
  required Location location,
}) async {
  final callable = _functions.httpsCallable(
    'calendar_functions-insert_event',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 60),
    ),
  );

  try {
    final result = await callable({
      ...event.toJson(),
      'isDev': isDev,
    });
    return EventModel.fromJson(result.data, location: location);
  } catch (err) {
    debugPrint('insertEvent failed: $err');
    rethrow;
  }
}

Future<dynamic> updateEvent(EventModel event) async {
  final callable = _functions.httpsCallable(
    'calendar_functions-update_event',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 60),
    ),
  );

  try {
    final result = await callable({
      ...event.toJson(),
      'isDev': isDev,
    });
    return result.data;
  } catch (err) {
    debugPrint('updateEvent failed: $err');
    rethrow;
  }
}

Future<dynamic> emailAttendees(
  EventModel event,
  String studentId, {
  bool isCancel = false,
}) async {
  final callable = _functions.httpsCallable(
    'email_attendees',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 60),
    ),
  );

  try {
    final result = await callable({
      ...event.toJson(),
      'studentId': studentId,
      'isCancel': isCancel,
    });
    return result.data;
  } catch (err) {
    debugPrint('emailAttendees failed: $err');
    rethrow;
  }
}
