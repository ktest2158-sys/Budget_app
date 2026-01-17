import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/storage_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // ✅ Explicitly uses the service folder version
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
      // ✅ Removed 'const' to allow the Dashboard to refresh its data
      home: DashboardScreen(), 
    );
  }
}