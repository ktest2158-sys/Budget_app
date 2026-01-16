import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/dashboard_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Initialize Hive with proper platform-specific path
    await Hive.initFlutter();

    // ✅ Initialize storage (open boxes, register adapters if any)
    await StorageService.init();

    // ✅ Launch app
    runApp(const BudgetApp());
  } catch (e, st) {
    // ❗ Catch startup errors so app doesn’t silently crash
    debugPrint('Startup failed: $e');
    debugPrint('$st');
  }
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget App',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
