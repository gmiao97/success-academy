import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

extension DateTimeUtils on TZDateTime {
  /// Returns [TZDateTime] of the most recent [weekday] of the same week.
  ///
  /// The [weekday] may be 0 for Sunday, 1 for Monday, etc. up to 7 for Sunday.
  TZDateTime mostRecentWeekday(int weekday) =>
      TZDateTime(location, year, month, day - (this.weekday - weekday) % 7);
}

/// Encapsulates a start and end [TZDateTime] that represent the range of dates.
class TZDateTimeRange extends DateTimeRange {
  TZDateTimeRange({required TZDateTime start, required TZDateTime end})
      : super(start: start, end: end);

  @override
  TZDateTime get start => super.start as TZDateTime;

  @override
  TZDateTime get end => super.end as TZDateTime;

  /// Returns whether [dateTimeRange] has overlap with this [TZDateTimeRange].
  bool overlaps(DateTimeRange dateTimeRange) =>
      !(start.isAfter(dateTimeRange.end) || end.isBefore(dateTimeRange.start));

  /// Returns whether [dateTimeRange] is fully contained in this
  /// [TZDateTimeRange].
  bool contains(DateTimeRange dateTimeRange) =>
      !dateTimeRange.start.isBefore(start) && !dateTimeRange.end.isAfter(end);
}

/// Merges any overlapping [TZDateTimeRange]s in [dateTimeRanges] and returns a
/// sorted list of the result.
List<TZDateTimeRange> mergeTZDateTimeRanges(
  List<TZDateTimeRange> dateTimeRanges,
) {
  if (dateTimeRanges.isEmpty) {
    return [];
  }

  dateTimeRanges.sort((a, b) => a.start.compareTo(b.start));
  final mergedDateTimeRanges = <TZDateTimeRange>[];
  var merged = dateTimeRanges[0];
  for (var i = 1; i < dateTimeRanges.length; i++) {
    if (merged.overlaps(dateTimeRanges[i])) {
      merged = TZDateTimeRange(
        start: merged.start.isBefore(dateTimeRanges[i].start)
            ? merged.start
            : dateTimeRanges[i].start,
        end: merged.end.isAfter(dateTimeRanges[i].end)
            ? merged.end
            : dateTimeRanges[i].end,
      );
    } else {
      mergedDateTimeRanges.add(merged);
      merged = dateTimeRanges[i];
    }
  }
  mergedDateTimeRanges.add(merged);
  dateTimeRanges
    ..clear()
    ..addAll(
      mergedDateTimeRanges,
    );
  return dateTimeRanges;
}
