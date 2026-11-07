import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // sqflite runs on native platforms; keep the browser prototype launchable.
  if (!kIsWeb) {
    await AppDatabase.instance.database;
  }
  runApp(const StockMateApp());
}
