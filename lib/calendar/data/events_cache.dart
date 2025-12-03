import 'package:flutter/material.dart';
import 'package:success_academy/calendar/data/event_model.dart';

/// Cache for [EventModel] data.
///
/// TODO: Implement a better caching solution rather than in-memory cache.
class EventsCache {
  EventsCache._();

  factory EventsCache() => _instance;

  static final EventsCache _instance = EventsCache._();

  final Set<EventModel> _eventsCache = {};

  Set<EventModel> get events => Set.of(_eventsCache);

  /// Clears all events from cache.
  void clearAll() {
    _eventsCache.clear();
  }

  /// Clears events from cache that falls within [dateTimeRange].
  ///
  /// Clears events with any overlap with [dateTimeRange] i.e. an end
  /// timestamp greater than `dateTimeRange.start` and a start timestamp less
  /// than `dateTimeRange.end`.
  void clearRange(DateTimeRange dateTimeRange) {
    _eventsCache.removeWhere(
      (event) =>
          event.endTime.isAfter(dateTimeRange.start) &&
          event.startTime.isBefore(dateTimeRange.end),
    );
  }

  /// Stores all [events] in cache.
  void storeAll(Iterable<EventModel> events) {
    _eventsCache.addAll(events);
  }

  /// Removes all events from cache that has event id contained in [eventIds].
  void removeAll(Iterable<String> eventIds) {
    _eventsCache.removeWhere((e) => eventIds.contains(e.eventId));
  }
}
