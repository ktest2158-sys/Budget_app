import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/storage_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Initialize storage service
  await StorageService.init();

  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _checkFirstLaunch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // ✅ FIXED: Use the proper isFirstLaunch flag
          final isFirstLaunch = snapshot.data ?? true;
          return isFirstLaunch
              ? const OnboardingScreen()
              : const DashboardScreen();
        },
      ),
    );
  }

  Future<bool> _checkFirstLaunch() async {
    // ✅ FIXED: Use the dedicated first launch flag instead of checking data existence
    return StorageService.isFirstLaunch();
  }
}
