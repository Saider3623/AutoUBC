import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'history_screen.dart';
import 'weekly_report_screen.dart';

class HistoryAndReportsScreen extends StatefulWidget {
  const HistoryAndReportsScreen({super.key});

  @override
  State<HistoryAndReportsScreen> createState() =>
      _HistoryAndReportsScreenState();
}

class _HistoryAndReportsScreenState extends State<HistoryAndReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.history),
            Tab(text: loc.weeklyReport),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              HistoryScreen(),
              WeeklyReportScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
