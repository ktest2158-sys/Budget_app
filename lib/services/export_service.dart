import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import '../models/income.dart';
import '../models/expense.dart';

class ExportService {
  static Future<String> exportToCsv() async {
    final incomeBox = Hive.box<Income>('incomes');
    final expenseBox = Hive.box<Expense>('expenses');

    List<List<dynamic>> rows = [];
    // Header row
    rows.add(["Type", "Name", "Category", "Amount", "Frequency"]);

    // Add Income data - Fixed 'title' to 'name' and removed 'date'
    for (var item in incomeBox.values) {
      rows.add([
        "Income", 
        item.name, 
        item.category, 
        item.amount, 
        item.frequency.toString()
      ]);
    }

    // Add Expense data - Fixed 'title' to 'name' and removed 'date'
    for (var item in expenseBox.values) {
      rows.add([
        "Expense", 
        item.name, 
        item.category, 
        item.amount, 
        item.frequency.toString()
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getExternalStorageDirectory();
    final path = "${directory!.path}/budget_backup_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);

    await file.writeAsString(csvData);
    return path;
  }
}