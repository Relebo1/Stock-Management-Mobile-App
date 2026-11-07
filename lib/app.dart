import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'features/app_shell/presentation/app_shell.dart';

class StockMateApp extends StatelessWidget {
  const StockMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
