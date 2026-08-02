/// Semantic state used by the weekly report UI and PDF.
enum WeeklyReportStatus {
  active,
  noMileage,
}

WeeklyReportStatus classifyWeeklyReportStatus(int distance) {
  return distance == 0
      ? WeeklyReportStatus.noMileage
      : WeeklyReportStatus.active;
}

extension WeeklyReportStatusX on WeeklyReportStatus {
  bool get isNoMileage => this == WeeklyReportStatus.noMileage;
}
