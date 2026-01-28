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

    // --- Populate categories if empty
    final catBox = Hive.box<String>(expenseCategoryBox);
    if (catBox.isEmpty) {
      await catBox.addAll([
        'Salary', 'Rental', 'Government', 'Debt', 'Family', 'Kids',
        'Housing', 'Transport', 'Utilities', 'Health', 'Digital',
        'Grocery', 'Savings', 'Miscellaneous',
      ]);
    }

    // --- Populate incomes if empty ---
    final incomeBoxInstance = Hive.box<Income>(incomeBox);
    if (incomeBoxInstance.isEmpty) {
      await incomeBoxInstance.addAll([
        Income(
          name: 'Perseus Salary',
          amount: 2300.0,
          category: 'Salary',
          frequency: Frequency.fortnightly,
          date: appStartDate,
        ),
        Income(
          name: 'AusPost Salary',
          amount: 850.0,
          category: 'Salary',
          frequency: Frequency.fortnightly,
          date: appStartDate,
        ),
        Income(
          name: 'Kara House',
          amount: 300.0,
          category: 'Home',
          frequency: Frequency.fortnightly,
          date: appStartDate,
        ),
        Income(
          name: 'Clink FTB',
          amount: 280.0,
          category: 'Government',
          frequency: Frequency.fortnightly,
          date: appStartDate,
        ),
      ]);
    }

    // --- Populate expense templates if empty ---
    final expenseBoxInstance = Hive.box<Expense>(expenseBox);
    if (expenseBoxInstance.isEmpty) {
      await expenseBoxInstance.addAll([
        Expense(name: 'Loan Repayment 1', amount: 800.0, category: 'Home', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'Loan Repayment 2', amount: 125.0, category: 'Home', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'CSA Payment', amount: 420.0, category: 'Government', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'OSHC', amount: 150.0, category: 'Kids', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'Spriggy', amount: 20.0, category: 'Kids', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'City of Swan', amount: 90.0, category: 'Home', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'RAC Car Insurance', amount: 88.0, category: 'Transport', frequency: Frequency.monthly, isTemplate: true),
        Expense(name: 'RAC Home Insurance', amount: 100.0, category: 'Home', frequency: Frequency.monthly, isTemplate: true),
        Expense(name: 'Water Corp', amount: 75.0, category: 'Utilities', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'Synergy (Elec)', amount: 30.0, category: 'Utilities', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'AGL (Gas)', amount: 22.0, category: 'Utilities', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'NBN', amount: 60.0, category: 'Utilities', frequency: Frequency.monthly, isTemplate: true),
        Expense(name: 'Mobile', amount: 40.0, category: 'Utilities', frequency: Frequency.monthly, isTemplate: true),
        Expense(name: 'Gym (Chasing Better)', amount: 24.34, category: 'Health', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'YouTube', amount: 10.0, category: 'Digital', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'Netflix', amount: 10.0, category: 'Digital', frequency: Frequency.monthly, isTemplate: true),
        Expense(name: 'Food', amount: 600.0, category: 'Grocery', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'Holiday Savings', amount: 300.0, category: 'Entertainment', frequency: Frequency.fortnightly, isTemplate: true),
        Expense(name: 'Birthday Savings', amount: 70.0, category: 'Entertainment', frequency: Frequency.fortnightly, isTemplate: true),
      ]);
    }
  }

  // --- TIME HELPERS ---
  static int getCurrentFortnightOffset() {
    final daysSinceStart = DateTime.now().difference(appStartDate).inDays;
    return (daysSinceStart / 14).floor();
  }

  static Map<String, DateTime> getFortnightRange(int userOffset) {
    final totalOffset = getCurrentFortnightOffset() + userOffset;
    final start = appStartDate.add(Duration(days: totalOffset * 14));
    final end = start.add(const Duration(days: 13, hours: 23, minutes: 59, seconds: 59));
    return {'start': start, 'end': end};
  }

  static Map<String, double> getDashboardSummary(int offset) {
    final range = getFortnightRange(offset);
    final incomes = getIncomes().where((inc) =>
        inc.date.isAfter(range['start']!.subtract(const Duration(seconds: 1))) &&
        inc.date.isBefore(range['end']!.add(const Duration(seconds: 1)))).toList();

    final expenses = getExpenses().where((exp) =>
        !exp.isTemplate &&
        exp.date != null &&
        exp.date!.isAfter(range['start']!.subtract(const Duration(seconds: 1))) &&
        exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1)))).toList();

    final totalIncome = incomes.fold(0.0, (sum, item) => sum + item.amount);
    final totalExpense = expenses.fold(0.0, (sum, item) => sum + item.amount);

    final totalLeft = totalIncome - totalExpense;
    final savingsCap = totalIncome * 0.20;

    double remaining = 0;
    double actualSavings = 0;

    if (totalLeft <= 300) {
      remaining = totalLeft > 0 ? totalLeft : 0;
      actualSavings = 0;
    } else {
      remaining = 300;
      final surplus = totalLeft - 300;
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

  // --- INCOME LOGIC ---
  static List<Income> getIncomes() => Hive.box<Income>(incomeBox).values.toList();
  static Future<void> saveIncome(Income income) async => Hive.box<Income>(incomeBox).put(income.id, income);
  static Future<void> deleteIncome(String id) async => Hive.box<Income>(incomeBox).delete(id);

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
  static List<Expense> getExpenses() => Hive.box<Expense>(expenseBox).values.toList();
  static List<Expense> getTemplates() => Hive.box<Expense>(expenseBox).values.where((e) => e.isTemplate).toList();
  static Future<void> saveExpense(Expense expense) async => Hive.box<Expense>(expenseBox).put(expense.id, expense);
  static Future<void> deleteExpense(String id) async => Hive.box<Expense>(expenseBox).delete(id);

  static Future<void> checkOffExpense(Expense template, int offset) async {
    final range = getFortnightRange(offset);
    final instance = template.createInstance(range['start']!);
    await saveExpense(instance);
  }

  // --- EXPENSE CATEGORY LOGIC ---
  static List<String> getExpenseCategories() => Hive.box<String>(expenseCategoryBox).values.toList();

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
}
