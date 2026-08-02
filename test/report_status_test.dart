import 'package:flutter_test/flutter_test.dart';
import 'package:autoubc/utils/report_status.dart';

void main() {
  group('classifyWeeklyReportStatus', () {
    test('classifies a zero-mileage partial period as no mileage', () {
      expect(
        classifyWeeklyReportStatus(0),
        WeeklyReportStatus.noMileage,
      );
    });

    test('classifies a full zero-mileage week as no mileage', () {
      expect(
        classifyWeeklyReportStatus(0).isNoMileage,
        isTrue,
      );
    });

    test('keeps a week with positive mileage active', () {
      expect(
        classifyWeeklyReportStatus(42),
        WeeklyReportStatus.active,
      );
    });
  });
}
