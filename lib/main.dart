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

          // Show onboarding if first launch, otherwise show dashboard
          final isFirstLaunch = snapshot.data ?? true;
          return isFirstLaunch
              ? const OnboardingScreen()
              : const DashboardScreen();
        },
      ),
    );
  }

  Future<bool> _checkFirstLaunch() async {
    // Check if this is the first launch by looking at settings
    final hasIncome = StorageService.getIncomes().isNotEmpty;
    final hasExpenses = StorageService.getExpenses().isNotEmpty;

    // If no income or expense templates exist, treat as first launch
    return !hasIncome && !hasExpenses;
  }
}
