import 'package:flutter/material.dart';

import '../features/entry/inspection_entry_page.dart';
import '../features/completion_review/completion_review_page.dart';
import '../features/inspection/inspection_overview_page.dart';
import '../models/inspection_session.dart';

abstract final class AppRoutes {
  static const entry = '/';
  static const inspection = '/inspection';
  static const completionReview = '/completion-review';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      inspection => MaterialPageRoute<void>(
        builder: (_) => InspectionOverviewPage(
          inspectionType:
              settings.arguments as InspectionType? ??
              InspectionType.returnVehicle,
        ),
        settings: settings,
      ),
      completionReview => MaterialPageRoute<void>(
        builder: (_) => const CompletionReviewPage(),
        settings: settings,
      ),
      _ => MaterialPageRoute<void>(
        builder: (_) => const InspectionEntryPage(),
        settings: const RouteSettings(name: entry),
      ),
    };
  }
}
