import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../features/orders/presentation/pages/orders_page.dart';

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
      home: const OrdersPage(),
    );
  }
}
