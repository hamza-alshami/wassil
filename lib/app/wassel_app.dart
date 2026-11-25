import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';

class WasselApp extends StatelessWidget {
  const WasselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'وصّل – وين طلبي؟',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      home: const _SetupPlaceholder(),
    );
  }
}

/// Temporary launch screen for the foundation phase.
/// The orders experience will be added in a later phase.
class _SetupPlaceholder extends StatelessWidget {
  const _SetupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('وصّل – وين طلبي؟'),
      ),
    );
  }
}
