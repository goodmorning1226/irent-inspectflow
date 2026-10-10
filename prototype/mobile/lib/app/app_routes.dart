import 'package:flutter/material.dart';

import '../features/entry/inspection_entry_page.dart';
import '../features/inspection/inspection_overview_page.dart';

abstract final class AppRoutes {
  static const entry = '/';
  static const inspection = '/inspection';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      inspection => MaterialPageRoute<void>(
        builder: (_) => const InspectionOverviewPage(),
        settings: settings,
      ),
      _ => MaterialPageRoute<void>(
        builder: (_) => const InspectionEntryPage(),
        settings: const RouteSettings(name: entry),
      ),
    };
  }
}
