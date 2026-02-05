// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/frequency.dart';

class StorageService {
  static const incomeBox = 'incomes';
  static const expenseBox = 'expenses';
  static const expenseCategoryBox = 'expense_categories';
  static const settingsBox = 'settings';
  static const fortnightStartKey = 'fortnight_start';
  static const minRemainingKey = 'min_remaining';
  static const savingsPercentKey = 'savings_percent';
  static const isFirstLaunchKey = 'is_first_launch';

  static final DateTime appStartDate = DateTime(2025, 12, 31);

  // --- INIT ---
  static Future<void> init() async {
    // --- Register adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(IncomeAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FrequencyAdapter());

    // --- Open boxes
    await Hive.openBox<Income>(incomeBox);
    await Hive.openBox<Expense>(expenseBox);
    await Hive.openBox<String>(expenseCategoryBox);
    await Hive.openBox<String>(settingsBox);

    // --- Populate default categories only if empty
    final catBox = Hive.box<String>(expenseCategoryBox);
    if (catBox.isEmpty) {
      await catBox.addAll([
        'Salary',
        'Rental',
        'Government',
        'Home',
        'Personal',
        'Kids',
        'Transport',
        'Utilities',
        'Grocery',
        'Entertainment',
        'Miscellaneous',
      ]);
    }

    // --- Initialize default settings if first launch
    final settingsBoxInstance = Hive.box<String>(settingsBox);
    if (settingsBoxInstance.get(isFirstLaunchKey) == null) {
      await settingsBoxInstance.put(isFirstLaunchKey, 'false');
      await settingsBoxInstance.put(minRemainingKey, '300.0');
      await settingsBoxInstance.put(savingsPercentKey, '20.0');
    }

    // Note: No hardcoded income or expense templates - users add their own
  }

  // --- SETTINGS GETTERS/SETTERS ---
  static double getMinRemaining() {
    final box = Hive.box<String>(settingsBox);
    final stored = box.get(minRemainingKey);
    return double.tryParse(stored ?? '300.0') ?? 300.0;
  }

  static Future<void> saveMinRemaining(double amount) async {
    final box = Hive.box<String>(settingsBox);
    await box.put(minRemainingKey, amount.toString());
  }

  static double getSavingsPercent() {
    final box = Hive.box<String>(settingsBox);
    final stored = box.get(savingsPercentKey);
    return double.tryParse(stored ?? '20.0') ?? 20.0;
  }

  static Future<void> saveSavingsPercent(double percent) async {
    final box = Hive.box<String>(settingsBox);
    await box.put(savingsPercentKey, percent.toString());
  }

  static bool isFirstLaunch() {
    final box = Hive.box<String>(settingsBox);
    return box.get(isFirstLaunchKey) != 'false';
  }

  static Future<void> completeFirstLaunch() async {
    final box = Hive.box<String>(settingsBox);
    await box.put(isFirstLaunchKey, 'false');
  }

  // --- TIME HELPERS ---
  static int getCurrentFortnightOffset() {
    final start = getFortnightStart();
    final daysSinceStart = DateTime.now().difference(start).inDays;
    return (daysSinceStart / 14).floor();
  }

  static Map<String, DateTime> getFortnightRange(int userOffset) {
    final start = getFortnightStart();
    final totalOffset = getCurrentFortnightOffset() + userOffset;
    final rangeStart = start.add(Duration(days: totalOffset * 14));
    final end = rangeStart
        .add(const Duration(days: 13, hours: 23, minutes: 59, seconds: 59));
    return {'start': rangeStart, 'end': end};
  }

  static Map<String, double> getDashboardSummary(int offset) {
    final range = getFortnightRange(offset);
    final incomes = getIncomes()
        .where((inc) =>
            inc.date.isAfter(
                range['start']!.subtract(const Duration(seconds: 1))) &&
            inc.date.isBefore(range['end']!.add(const Duration(seconds: 1))))
        .toList();

    final expenses = getExpenses()
        .where((exp) =>
            !exp.isTemplate &&
            exp.date != null &&
            exp.date!.isAfter(
                range['start']!.subtract(const Duration(seconds: 1))) &&
            exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
        .toList();

    final totalIncome = incomes.fold(0.0, (sum, item) => sum + item.amount);
    final totalExpense = expenses.fold(0.0, (sum, item) => sum + item.amount);

    final totalLeft = totalIncome - totalExpense;
    final minRemaining = getMinRemaining();
    final savingsPercent = getSavingsPercent();
    final savingsCap = totalIncome * (savingsPercent / 100);

    double remaining = 0;
    double actualSavings = 0;

    if (totalLeft <= minRemaining) {
      remaining = totalLeft > 0 ? totalLeft : 0;
      actualSavings = 0;
    } else {
      remaining = minRemaining;
      final surplus = totalLeft - minRemaining;
      if (surplus <= savingsCap) {
        actualSavings = surplus;
      } else {
        actualSavings = savingsCap;
        remaining += (surplus - savingsCap);
      }
    }

    return {
      'income': totalIncome,
      'expenses': totalExpense,
      'savings': actualSavings,
      'remaining': remaining,
    };
  }

  static List<ChartData> getCategoryTotals(int offset) {
    final range = getFortnightRange(offset);
    final Map<String, double> categoryMap = {};

    final checkedOffExpenses = getExpenses()
        .where((exp) =>
            !exp.isTemplate &&
            exp.date != null &&
            exp.date!.isAfter(
                range['start']!.subtract(const Duration(seconds: 1))) &&
            exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
        .toList();

    for (var exp in checkedOffExpenses) {
      categoryMap[exp.category] = (categoryMap[exp.category] ?? 0) + exp.amount;
    }

    return categoryMap.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList();
  }

  // --- INCOME LOGIC ---
  static List<Income> getIncomes() =>
      Hive.box<Income>(incomeBox).values.toList();
  static Future<void> saveIncome(Income income) async =>
      Hive.box<Income>(incomeBox).put(income.id, income);
  static Future<void> deleteIncome(String id) async =>
      Hive.box<Income>(incomeBox).delete(id);

  static Future<void> checkOffIncome(Income template, int offset) async {
    final range = getFortnightRange(offset);
    final instance = Income(
      name: template.name,
      amount: template.amount,
      category: template.category,
      frequency: template.frequency,
      date: range['start']!,
    );
    await saveIncome(instance);
  }

  // --- EXPENSE LOGIC ---
  static List<Expense> getExpenses() =>
      Hive.box<Expense>(expenseBox).values.toList();
  static List<Expense> getTemplates() =>
      Hive.box<Expense>(expenseBox).values.where((e) => e.isTemplate).toList();
  static Future<void> saveExpense(Expense expense) async =>
      Hive.box<Expense>(expenseBox).put(expense.id, expense);
  static Future<void> deleteExpense(String id) async =>
      Hive.box<Expense>(expenseBox).delete(id);

  static Future<void> addExpense({
    required String name,
    required String category,
    required double amount,
    required Frequency frequency,
    required bool isTemplate,
    DateTime? date,
  }) async {
    final newExpense = Expense(
      name: name,
      category: category,
      amount: amount,
      frequency: frequency,
      isTemplate: isTemplate,
      date: date,
    );
    await saveExpense(newExpense);
  }

  static Future<void> checkOffExpense(Expense template, int offset) async {
    final range = getFortnightRange(offset);
    final instance = template.createInstance(range['start']!);
    await saveExpense(instance);
  }

  // ✅ New Filter Method for Chart Drill-down
  static List<Expense> getExpensesByCategory(int offset, String category) {
    final range = getFortnightRange(offset);
    return getExpenses()
        .where((exp) =>
            !exp.isTemplate &&
            exp.category == category &&
            exp.date != null &&
            exp.date!.isAfter(
                range['start']!.subtract(const Duration(seconds: 1))) &&
            exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
        .toList();
  }

  // --- EXPENSE CATEGORY LOGIC ---
  static List<String> getExpenseCategories() =>
      Hive.box<String>(expenseCategoryBox).values.toList();

  static Future<void> saveExpenseCategory(String category) async {
    final box = Hive.box<String>(expenseCategoryBox);
    if (!box.values.contains(category)) {
      await box.add(category);
    }
  }

  static Future<void> deleteExpenseCategory(String category) async {
    final box = Hive.box<String>(expenseCategoryBox);
    final key = box.keys.firstWhere(
      (k) => box.get(k) == category,
      orElse: () => null,
    );
    if (key != null) {
      await box.delete(key);
    }
  }

  // --- SETTINGS: Fortnight Start ---
  static DateTime getFortnightStart() {
    final box = Hive.box<String>(settingsBox);
    final stored = box.get(fortnightStartKey);
    if (stored != null) {
      return DateTime.parse(stored);
    }
    return appStartDate;
  }

  static Future<void> saveFortnightStart(DateTime date) async {
    final box = Hive.box<String>(settingsBox);
    await box.put(fortnightStartKey, date.toIso8601String());
  }

  // --- DATA MANAGEMENT ---
  static Future<void> clearAllData() async {
    await Hive.box<Income>(incomeBox).clear();
    await Hive.box<Expense>(expenseBox).clear();
  }

  static Future<void> resetToDefaults() async {
    final settingsBoxInstance = Hive.box<String>(settingsBox);
    await settingsBoxInstance.put(minRemainingKey, '300.0');
    await settingsBoxInstance.put(savingsPercentKey, '20.0');
    await settingsBoxInstance.put(
        fortnightStartKey, appStartDate.toIso8601String());
  }
}

class ChartData {
  ChartData(this.category, this.amount);
  final String category;
  final double amount;
}
