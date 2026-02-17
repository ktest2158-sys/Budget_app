// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/frequency.dart';
import 'package:flutter/material.dart';

class StorageService {
  static const incomeBox = 'incomes';
  static const expenseBox = 'expenses';
  static const expenseCategoryBox = 'expense_categories';
  static const settingsBox = 'settings';
  static const fortnightStartKey = 'fortnight_start';
  static const minRemainingKey = 'min_remaining';
  static const savingsPercentKey = 'savings_percent';
  static const isFirstLaunchKey = 'is_first_launch';
  static const showChartKey = 'show_chart'; // ✅ NEW

  static DateTime get appStartDate => getFortnightStart();

  // --- INIT ---
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(IncomeAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FrequencyAdapter());

    await Hive.openBox<Income>(incomeBox);
    await Hive.openBox<Expense>(expenseBox);
    await Hive.openBox<String>(expenseCategoryBox);
    await Hive.openBox<String>(settingsBox);

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

    final settingsBoxInstance = Hive.box<String>(settingsBox);
    if (settingsBoxInstance.get(isFirstLaunchKey) == null) {
      await settingsBoxInstance.put(isFirstLaunchKey, 'true');
      await settingsBoxInstance.put(minRemainingKey, '300.0');
      await settingsBoxInstance.put(savingsPercentKey, '20.0');
      await settingsBoxInstance.put(showChartKey, 'true'); // ✅ Default chart on

      if (settingsBoxInstance.get(fortnightStartKey) == null) {
        await settingsBoxInstance.put(
            fortnightStartKey, DateTime.now().toIso8601String());
      }
    }
  }

  // --- SETTINGS: Chart Toggle ---
  static bool getShowChart() {
    final box = Hive.box<String>(settingsBox);
    return box.get(showChartKey) != 'false'; // Defaults to true
  }

  static Future<void> saveShowChart(bool show) async {
    final box = Hive.box<String>(settingsBox);
    await box.put(showChartKey, show.toString());
  }

  // --- SETTINGS GETTERS/SETTERS ---
  static double getMinRemaining() {
    final box = Hive.box<String>(settingsBox);
    return double.tryParse(box.get(minRemainingKey) ?? '300.0') ?? 300.0;
  }

  static Future<void> saveMinRemaining(double amount) async {
    final box = Hive.box<String>(settingsBox);
    await box.put(minRemainingKey, amount.toString());
  }

  static double getSavingsPercent() {
    final box = Hive.box<String>(settingsBox);
    return double.tryParse(box.get(savingsPercentKey) ?? '20.0') ?? 20.0;
  }

  static Future<void> saveSavingsPercent(double percent) async {
    final box = Hive.box<String>(settingsBox);
    await box.put(savingsPercentKey, percent.toString());
  }

  static bool isFirstLaunch() {
    final box = Hive.box<String>(settingsBox);
    return box.get(isFirstLaunchKey) == 'true';
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

  // ✅ UPDATED: Savings = cumulative. Remaining = cumulative. Expenses = current fortnight only (excludes savings).
  static Map<String, double> getDashboardSummary(int offset) {
    final range = getFortnightRange(offset);

    // Current fortnight income
    final incomes = getIncomes()
        .where((inc) =>
            inc.date.isAfter(
                range['start']!.subtract(const Duration(seconds: 1))) &&
            inc.date.isBefore(range['end']!.add(const Duration(seconds: 1))))
        .toList();

    // Current fortnight regular expenses only (no savings, no withdrawals)
    final expenses = getExpenses()
        .where((exp) =>
            !exp.isTemplate &&
            !exp.isSavings &&
            !exp.isSavingsWithdrawal &&
            exp.date != null &&
            exp.date!.isAfter(
                range['start']!.subtract(const Duration(seconds: 1))) &&
            exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
        .toList();

    final totalIncome = incomes.fold(0.0, (sum, item) => sum + item.amount);
    final totalExpense = expenses.fold(0.0, (sum, item) => sum + item.amount);

    return {
      'income': totalIncome,
      'expenses': totalExpense,
      'savings': getCumulativeSavings(), // ✅ All-time cumulative
      'remaining': getCumulativeRemaining(), // ✅ All-time cumulative
    };
  }

  // ✅ NEW: Cumulative savings = all contributions minus all withdrawals, all time
  static double getCumulativeSavings() {
    final allExpenses = getExpenses().where((exp) => !exp.isTemplate);
    final contributions = allExpenses
        .where((exp) => exp.isSavings && !exp.isSavingsWithdrawal)
        .fold(0.0, (sum, exp) => sum + exp.amount);
    final withdrawals = allExpenses
        .where((exp) => exp.isSavingsWithdrawal)
        .fold(0.0, (sum, exp) => sum + exp.amount);
    return contributions - withdrawals;
  }

  // ✅ NEW: Cumulative remaining across all fortnights — true balance, can go negative
  static double getCumulativeRemaining() {
    final currentOffset = getCurrentFortnightOffset();
    double total = 0.0;

    // Loop from fortnight 0 to current (inclusive)
    for (int i = 0; i <= currentOffset; i++) {
      final absoluteOffset = i - currentOffset; // Convert to relative offset
      final range = getFortnightRange(absoluteOffset);

      final income = getIncomes()
          .where((inc) =>
              inc.date.isAfter(
                  range['start']!.subtract(const Duration(seconds: 1))) &&
              inc.date.isBefore(range['end']!.add(const Duration(seconds: 1))))
          .fold(0.0, (sum, inc) => sum + inc.amount);

      final expenses = getExpenses()
          .where((exp) =>
              !exp.isTemplate &&
              !exp.isSavings &&
              !exp.isSavingsWithdrawal &&
              exp.date != null &&
              exp.date!.isAfter(
                  range['start']!.subtract(const Duration(seconds: 1))) &&
              exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
          .fold(0.0, (sum, exp) => sum + exp.amount);

      final savings = getExpenses()
          .where((exp) =>
              !exp.isTemplate &&
              exp.isSavings &&
              !exp.isSavingsWithdrawal &&
              exp.date != null &&
              exp.date!.isAfter(
                  range['start']!.subtract(const Duration(seconds: 1))) &&
              exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
          .fold(0.0, (sum, exp) => sum + exp.amount);

      total += income - expenses - savings;
    }

    return total;
  }

  // ✅ NEW: Savings breakdown grouped by fortnight, sorted most recent first
  // Each fortnight has a header and individual named lines (contributions + withdrawals)
  static List<SavingsFortnightGroup> getSavingsBreakdown() {
    final allSavingsRecords = getExpenses()
        .where((exp) =>
            !exp.isTemplate &&
            exp.date != null &&
            (exp.isSavings || exp.isSavingsWithdrawal))
        .toList();

    if (allSavingsRecords.isEmpty) return [];

    final fortnightStart = getFortnightStart();
    final Map<int, List<Expense>> grouped = {};

    for (var exp in allSavingsRecords) {
      final daysSince = exp.date!.difference(fortnightStart).inDays;
      final index = (daysSince / 14).floor();
      grouped[index] ??= [];
      grouped[index]!.add(exp);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((index) {
      final rangeStart = fortnightStart.add(Duration(days: index * 14));
      final rangeEnd = rangeStart.add(const Duration(days: 13));
      final label =
          '${rangeStart.day}/${rangeStart.month} - ${rangeEnd.day}/${rangeEnd.month}';

      final items = grouped[index]!;
      final subtotal = items.fold(0.0, (sum, exp) {
        return sum + (exp.isSavingsWithdrawal ? -exp.amount : exp.amount);
      });

      return SavingsFortnightGroup(
        label: label,
        items: items,
        subtotal: subtotal,
      );
    }).toList();
  }

  // ✅ NEW: Remaining breakdown — one row per fortnight, sorted most recent first
  static List<RemainingFortnightRow> getRemainingBreakdown() {
    final currentOffset = getCurrentFortnightOffset();
    final List<RemainingFortnightRow> rows = [];

    for (int i = currentOffset; i >= 0; i--) {
      final absoluteOffset = i - currentOffset;
      final range = getFortnightRange(absoluteOffset);

      final income = getIncomes()
          .where((inc) =>
              inc.date.isAfter(
                  range['start']!.subtract(const Duration(seconds: 1))) &&
              inc.date.isBefore(range['end']!.add(const Duration(seconds: 1))))
          .fold(0.0, (sum, inc) => sum + inc.amount);

      final expenses = getExpenses()
          .where((exp) =>
              !exp.isTemplate &&
              !exp.isSavings &&
              !exp.isSavingsWithdrawal &&
              exp.date != null &&
              exp.date!.isAfter(
                  range['start']!.subtract(const Duration(seconds: 1))) &&
              exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
          .fold(0.0, (sum, exp) => sum + exp.amount);

      final savings = getExpenses()
          .where((exp) =>
              !exp.isTemplate &&
              exp.isSavings &&
              !exp.isSavingsWithdrawal &&
              exp.date != null &&
              exp.date!.isAfter(
                  range['start']!.subtract(const Duration(seconds: 1))) &&
              exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
          .fold(0.0, (sum, exp) => sum + exp.amount);

      final fortnightRemaining = income - expenses - savings;

      // Only include fortnights that have any activity
      if (income > 0 || expenses > 0 || savings > 0) {
        final label =
            '${range['start']!.day}/${range['start']!.month} - ${range['end']!.day}/${range['end']!.month}';
        rows.add(RemainingFortnightRow(
          label: label,
          amount: fortnightRemaining,
        ));
      }
    }

    return rows;
  }

  // Category chart — excludes savings contributions and withdrawals
  static List<ChartData> getCategoryTotals(int offset) {
    final range = getFortnightRange(offset);
    final Map<String, double> categoryMap = {};

    final checkedOffExpenses = getExpenses()
        .where((exp) =>
            !exp.isTemplate &&
            !exp.isSavings &&
            !exp.isSavingsWithdrawal &&
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

  static List<Color> getChartColors() {
    return const [
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFF44336),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
      Color(0xFFFFEB3B),
      Color(0xFF795548),
      Color(0xFF607D8B),
      Color(0xFFE91E63),
      Color(0xFF3F51B5),
      Color(0xFF009688),
      Color(0xFFCDDC39),
      Color(0xFFFFC107),
      Color(0xFF673AB7),
    ];
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
    bool isSavings = false,
    String? savingsBucket,
    bool isSavingsWithdrawal = false,
  }) async {
    final newExpense = Expense(
      name: name,
      category: category,
      amount: amount,
      frequency: frequency,
      isTemplate: isTemplate,
      date: date,
      isSavings: isSavings,
      savingsBucket: savingsBucket,
      isSavingsWithdrawal: isSavingsWithdrawal,
    );
    await saveExpense(newExpense);
  }

  static Future<void> checkOffExpense(Expense template, int offset) async {
    final range = getFortnightRange(offset);
    final instance = template.createInstance(range['start']!);
    await saveExpense(instance);
  }

  static List<Expense> getExpensesByCategory(int offset, String category) {
    final range = getFortnightRange(offset);
    return getExpenses()
        .where((exp) =>
            !exp.isTemplate &&
            !exp.isSavings &&
            !exp.isSavingsWithdrawal &&
            exp.category == category &&
            exp.date != null &&
            exp.date!.isAfter(
                range['start']!.subtract(const Duration(seconds: 1))) &&
            exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
        .toList();
  }

  // ✅ NEW: Get savings template names for withdrawal dropdown
  static List<String> getSavingsBucketNames() {
    return getTemplates().where((t) => t.isSavings).map((t) => t.name).toList();
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

    final allExpenses = getExpenses();
    for (var expense in allExpenses) {
      if (expense.category == category) {
        expense.category = 'Miscellaneous';
        await saveExpense(expense);
      }
    }

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
    if (stored != null) return DateTime.parse(stored);
    return DateTime.now();
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
        fortnightStartKey, DateTime.now().toIso8601String());
  }
}

// --- DATA CLASSES ---

class ChartData {
  ChartData(this.category, this.amount);
  final String category;
  final double amount;
}

// ✅ NEW: Savings breakdown — one fortnight group with named lines
class SavingsFortnightGroup {
  final String label;
  final List<Expense> items;
  final double subtotal;

  SavingsFortnightGroup({
    required this.label,
    required this.items,
    required this.subtotal,
  });
}

// ✅ NEW: Remaining breakdown — one row per fortnight
class RemainingFortnightRow {
  final String label;
  final double amount;

  RemainingFortnightRow({required this.label, required this.amount});
}
