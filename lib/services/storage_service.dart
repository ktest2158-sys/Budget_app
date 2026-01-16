// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/frequency.dart'; // Make sure FrequencyAdapter is imported

class StorageService {
  static const incomeBox = 'incomes';
  static const expenseBox = 'expenses';
  static const expenseCategoryBox = 'expense_categories';
  static const settingsBox = 'settings';
  static const fortnightStartKey = 'fortnight_start';

  /// ----------------
  /// Initialization
  /// ----------------
  static Future<void> init() async {
    // Register adapters once
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(IncomeAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FrequencyAdapter());

    // Open boxes safely
    if (!Hive.isBoxOpen(incomeBox)) await Hive.openBox<Income>(incomeBox);
    if (!Hive.isBoxOpen(expenseBox)) await Hive.openBox<Expense>(expenseBox);
    if (!Hive.isBoxOpen(expenseCategoryBox)) await Hive.openBox<String>(expenseCategoryBox);
    if (!Hive.isBoxOpen(settingsBox)) await Hive.openBox<String>(settingsBox);

    // Add default categories if empty
    final catBox = Hive.box<String>(expenseCategoryBox);
    if (catBox.isEmpty) {
      await catBox.addAll([
        'Home',
        'Groceries',
        'Utilities',
        'Transport',
        'Health / Medical',
        'Entertainment',
        'Subscriptions',
        'Education / Kids',
        'Miscellaneous',
      ]);
    }

    // Fortnight start (stored in settings box)
    final settings = Hive.box<String>(settingsBox);
    if (!settings.containsKey(fortnightStartKey)) {
      await settings.put(fortnightStartKey, DateTime.now().toIso8601String());
    }
  }

  /// ----------------
  /// Fortnight Start
  /// ----------------
  static DateTime getFortnightStart() {
    final box = Hive.box<String>(settingsBox);
    final str = box.get(fortnightStartKey);
    return str != null ? DateTime.parse(str) : DateTime.now();
  }

  static Future<void> saveFortnightStart(DateTime dt) async {
    final box = Hive.box<String>(settingsBox);
    await box.put(fortnightStartKey, dt.toIso8601String());
  }

  /// ----------------
  /// Expense Categories
  /// ----------------
  static List<String> getExpenseCategories() {
    return Hive.box<String>(expenseCategoryBox).values.toList();
  }

  static Future<void> saveExpenseCategory(String category) async {
    final box = Hive.box<String>(expenseCategoryBox);
    if (!box.values.contains(category)) await box.add(category);
  }

  static Future<void> deleteExpenseCategory(String category) async {
    final catBox = Hive.box<String>(expenseCategoryBox);
    final key = catBox.keys.cast<dynamic?>().firstWhere(
      (k) => catBox.get(k) == category,
      orElse: () => null,
    );

    if (key != null) await catBox.delete(key);

    // Reassign expenses using this category to "Miscellaneous"
    final expBox = Hive.box<Expense>(expenseBox);
    for (final exp in expBox.values) {
      if (exp.category == category) {
        exp.category = 'Miscellaneous';
        await exp.save();
      }
    }
  }

  /// ----------------
  /// Income
  /// ----------------
  static List<Income> getIncomes() =>
      Hive.box<Income>(incomeBox).values.toList();

  static Future<void> saveIncome(Income income) async =>
      Hive.box<Income>(incomeBox).put(income.id, income);

  static Future<void> deleteIncome(String id) async =>
      Hive.box<Income>(incomeBox).delete(id);

  /// ----------------
  /// Expenses
  /// ----------------
  static List<Expense> getExpenses() =>
      Hive.box<Expense>(expenseBox).values.toList();

  static Future<void> saveExpense(Expense expense) async =>
      Hive.box<Expense>(expenseBox).put(expense.id, expense);

  static Future<void> deleteExpense(String id) async =>
      Hive.box<Expense>(expenseBox).delete(id);
}
