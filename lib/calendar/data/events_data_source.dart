import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:success_academy/calendar/data/event_model.dart';
import 'package:success_academy/calendar/data/events_cache.dart';
import 'package:success_academy/calendar/services/event_service.dart'
    as event_service;
import 'package:success_academy/helpers/tz_date_time.dart';

/// DataSource to handle fetching and caching of event data.
final class EventsDataSource extends ChangeNotifier {
  static final Logger _logger = Logger();

  final EventsCache _eventsCache = EventsCache();
  final List<TZDateTimeRange> _cachedDateTimeRanges = [];

  List<TZDateTimeRange> get cachedDateTimeRanges => _cachedDateTimeRanges;

  /// Loads all currently stored events.
  Future<Set<EventModel>> loadData() async => _eventsCache.events;

  /// Loads event data that falls within [dateTimeRange].
  ///
  /// Includes events with any overlap with [dateTimeRange] i.e. an end
  /// timestamp greater than `dateTimeRange.start` and a start timestamp less
  /// than `dateTimeRange.end`.
  Future<Set<EventModel>> loadDataByKey(TZDateTimeRange dateTimeRange) async {
    if (!_cachedDateTimeRanges.any((range) => range.contains(dateTimeRange))) {
      await fetchAndStoreDataByKey(dateTimeRange);
    }
    return Future.value(
      _eventsCache.events
          .where(
            (event) =>
                event.endTime.isAfter(dateTimeRange.start) &&
                event.startTime.isBefore(dateTimeRange.end),
          )
          .toSet(),
    );
  }

  /// Fetches and stores event data by [dateTimeRange].
  Future<void> fetchAndStoreDataByKey(TZDateTimeRange dateTimeRange) async {
    _eventsCache
      ..clearRange(dateTimeRange)
      ..storeAll(
        await event_service.listEvents(
          location: dateTimeRange.start.location,
          dateTimeRange: dateTimeRange,
          singleEvents: true,
        ),
      );
    _cachedDateTimeRanges.add(dateTimeRange);
    mergeTZDateTimeRanges(_cachedDateTimeRanges);
    return;
  }

  /// Stores [event] in local storage.
  void storeEvent(EventModel event) {
    _eventsCache.storeAll([event]);
    notifyListeners();
  }

  /// Fetches instances of recurring [event] and stores them in local storage.
  Future<void> storeInstances(EventModel event) async {
    if (event.recurrence.isEmpty) {
      _logger.w('Called storeInstances with a non-recurrence event');
      return Future.value();
    }
    for (final dateTimeRange in _cachedDateTimeRanges) {
      _eventsCache.storeAll(
        await event_service.listInstances(
          eventId: event.eventId!,
          location: dateTimeRange.start.location,
          dateTimeRange: dateTimeRange,
        ),
      );
    }
    notifyListeners();
  }

  void removeEvent({
    required String eventId,
    bool isRecurrence = false,
    DateTime? start,
  }) {
    List<String> eventsToRemove;
    if (isRecurrence) {
      eventsToRemove = _eventsCache.events
          .where((e) {
            if (start != null) {
              return !e.startTime.isBefore(start) && e.recurrenceId == eventId;
            }
            return e.recurrenceId == eventId;
          })
          .map(
            (e) => e.eventId,
          )
          .nonNulls
          .toList();
    } else {
      eventsToRemove = _eventsCache.events
          .where((e) => e.eventId == eventId)
          .map(
            (e) => e.eventId,
          )
          .nonNulls
          .toList();
    }
    _eventsCache.removeAll(eventsToRemove);
    notifyListeners();
  }
}
