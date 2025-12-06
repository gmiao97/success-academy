import 'package:flutter_test/flutter_test.dart';
import 'package:success_academy/helpers/tz_date_time.dart';
import 'package:timezone/data/latest_10y.dart';
import 'package:timezone/timezone.dart';

final location = getLocation('America/New_York');

void main() {
  setUpAll(() {
    initializeTimeZones();
  });

  group('Test TZDateTime functionality', () {
    test('overlaps', () {
      final dateTimeRange = _createTZDateTimeRange(1000, 2000);

      expect(dateTimeRange.overlaps(_createTZDateTimeRange(500, 900)), false);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(500, 1000)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(500, 1500)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(500, 2000)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(500, 2500)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(1000, 1500)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(1000, 2000)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(1000, 2500)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(1500, 1900)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(1500, 2000)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(1000, 2500)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(2000, 3000)), true);
      expect(dateTimeRange.overlaps(_createTZDateTimeRange(2500, 3000)), false);
    });

    test('contains', () {
      final dateTimeRange = _createTZDateTimeRange(1000, 2000);

      expect(dateTimeRange.contains(_createTZDateTimeRange(500, 900)), false);
      expect(dateTimeRange.contains(_createTZDateTimeRange(500, 1000)), false);
      expect(dateTimeRange.contains(_createTZDateTimeRange(500, 1500)), false);
      expect(dateTimeRange.contains(_createTZDateTimeRange(500, 2000)), false);
      expect(dateTimeRange.contains(_createTZDateTimeRange(500, 2500)), false);
      expect(dateTimeRange.contains(_createTZDateTimeRange(1000, 1500)), true);
      expect(dateTimeRange.contains(_createTZDateTimeRange(1000, 2000)), true);
      expect(dateTimeRange.contains(_createTZDateTimeRange(1000, 2500)), false);
      expect(dateTimeRange.contains(_createTZDateTimeRange(1500, 1900)), true);
      expect(dateTimeRange.contains(_createTZDateTimeRange(1500, 2000)), true);
      expect(dateTimeRange.contains(_createTZDateTimeRange(1000, 2500)), false);
      expect(dateTimeRange.contains(_createTZDateTimeRange(2000, 3000)), false);
      expect(dateTimeRange.contains(_createTZDateTimeRange(2500, 3000)), false);
    });
  });

  group('Test mergeTZDateTimeRanges', () {
    test('no overlap, should return same list, sorted', () {
      final dateTimeRanges = [
        _createTZDateTimeRange(1000, 2000),
        _createTZDateTimeRange(700, 750),
        _createTZDateTimeRange(2100, 3000),
      ];

      final result = mergeTZDateTimeRanges(dateTimeRanges);

      expect(result, dateTimeRanges);
      expect(dateTimeRanges, [
        _createTZDateTimeRange(700, 750),
        _createTZDateTimeRange(1000, 2000),
        _createTZDateTimeRange(2100, 3000),
      ]);
    });

    test('overlap, should return merged list, sorted', () {
      final dateTimeRanges = [
        _createTZDateTimeRange(5000, 9000),
        _createTZDateTimeRange(1000, 2000),
        _createTZDateTimeRange(1800, 2200),
        _createTZDateTimeRange(8900, 9300),
        _createTZDateTimeRange(800, 1000),
        _createTZDateTimeRange(6000, 7000),
      ];

      final result = mergeTZDateTimeRanges(dateTimeRanges);

      expect(result, dateTimeRanges);
      expect(dateTimeRanges, [
        _createTZDateTimeRange(800, 2200),
        _createTZDateTimeRange(5000, 9300),
      ]);
    });
  });
}

TZDateTimeRange _createTZDateTimeRange(
  int startMillis,
  int endMillis,
) =>
    TZDateTimeRange(
      start: TZDateTime.fromMillisecondsSinceEpoch(location, startMillis),
      end: TZDateTime.fromMillisecondsSinceEpoch(location, endMillis),
    );
