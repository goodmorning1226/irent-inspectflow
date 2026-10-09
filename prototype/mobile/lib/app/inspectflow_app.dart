import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_routes.dart';

class InspectFlowApp extends StatelessWidget {
  const InspectFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iRent InspectFlow Prototype',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.entry,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
