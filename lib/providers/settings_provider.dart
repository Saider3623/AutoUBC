import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences such as the working week mode.
class SettingsProvider extends ChangeNotifier {
  static const _workWeekDaysKey = 'work_week_days';

  /// Working week length in days (5 = Mon–Fri, 6 = Mon–Sat).
  static const int fiveDayWeek = 5;
  static const int sixDayWeek = 6;

  /// The default working week is six days (Mon–Sat).
  static const int defaultWorkWeekDays = sixDayWeek;

  int _workWeekDays = defaultWorkWeekDays;

  int get workWeekDays => _workWeekDays;

  Future<void> loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_workWeekDaysKey);
    if (stored == fiveDayWeek || stored == sixDayWeek) {
      _workWeekDays = stored!;
    }
    notifyListeners();
  }

  Future<void> setWorkWeekDays(int days) async {
    if (days != fiveDayWeek && days != sixDayWeek) return;
    if (_workWeekDays == days) return;

    _workWeekDays = days;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_workWeekDaysKey, days);
  }
}
