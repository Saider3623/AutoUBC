import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:autoubc/models/fuel_log.dart';
import 'package:autoubc/services/report_service.dart';

void main() {
  setUpAll(initializeDateFormatting);

  group('buildReportFileName', () {
    test('uses the Russian localized month name', () {
      expect(
        buildReportFileName(
          'АХ9323',
          DateTime(2026, 6),
          'ru',
        ),
        'АХ9323_Июнь.pdf',
      );
    });

    test('uses the Ukrainian localized month name', () {
      expect(
        buildReportFileName(
          'АХ9323',
          DateTime(2026, 6),
          'uk',
        ),
        'АХ9323_Червень.pdf',
      );
    });

    test('uses the English localized month name', () {
      expect(
        buildReportFileName(
          'AH9323',
          DateTime(2026, 6),
          'en',
        ),
        'AH9323_June.pdf',
      );
    });

    test('preserves a Cyrillic car name when the app language is English', () {
      expect(
        buildReportFileName(
          'АХ9323',
          DateTime(2026, 6),
          'en',
        ),
        'АХ9323_June.pdf',
      );
    });

    test('sanitizes invalid filename characters in the car name', () {
      expect(
        buildReportFileName(
          'AH/9323',
          DateTime(2026, 6),
          'en',
        ),
        'AH_9323_June.pdf',
      );
    });
    test('groups weekly refuels by exact fuel type', () {
      final gas = FuelLog()
        ..fuelType = 'ГАЗ'
        ..liters = 30;
      final petrol = FuelLog()
        ..fuelType = '95'
        ..liters = 20.5;
      final secondGas = FuelLog()
        ..fuelType = 'ГАЗ'
        ..liters = 12;

      final summaries = summarizeFuelLogsByType([gas, petrol, secondGas]);

      expect(
        summaries
            .map((summary) => (
                  type: summary.fuelType,
                  count: summary.refuelCount,
                  liters: summary.totalLiters,
                ))
            .toList(),
        [
          (type: '95', count: 1, liters: 20.5),
          (type: 'ГАЗ', count: 2, liters: 42.0),
        ],
      );
      expect(
        summaries.fold<int>(
          0,
          (total, summary) => total + summary.refuelCount,
        ),
        3,
      );
    });

    test('keeps arbitrary fuel types separate', () {
      final diesel = FuelLog()
        ..fuelType = 'Diesel'
        ..liters = 31.2;
      final electric = FuelLog()
        ..fuelType = 'Electric'
        ..liters = 18.4;
      final secondDiesel = FuelLog()
        ..fuelType = 'Diesel'
        ..liters = 9.8;

      final summaries =
          summarizeFuelLogsByType([secondDiesel, electric, diesel]);

      expect(
        summaries
            .map((summary) => (
                  type: summary.fuelType,
                  count: summary.refuelCount,
                  liters: summary.totalLiters,
                ))
            .toList(),
        [
          (type: 'Diesel', count: 2, liters: 41.0),
          (type: 'Electric', count: 1, liters: 18.4),
        ],
      );
    });

    test('ignores blank fuel types while grouping refuels', () {
      final blank = FuelLog()
        ..fuelType = '  '
        ..liters = 15;

      expect(summarizeFuelLogsByType([blank]), isEmpty);
    });
  });
}
