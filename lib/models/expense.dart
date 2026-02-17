import 'package:hive/hive.dart';
import 'frequency.dart';
import 'package:uuid/uuid.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  double amount;

  @HiveField(4)
  Frequency frequency;

  @HiveField(5)
  bool isChecked;

  @HiveField(6)
  DateTime? date;

  @HiveField(7)
  bool isTemplate;

  // ✅ Marks this expense as a savings contribution (deducted from spendable pool, tracked separately)
  @HiveField(8)
  bool isSavings;

  // ✅ For withdrawals: which savings bucket this was paid from (e.g. "Holiday Fund")
  @HiveField(9)
  String? savingsBucket;

  // ✅ Marks this as a one-off withdrawal from a savings bucket
  @HiveField(10)
  bool isSavingsWithdrawal;

  Expense({
    String? id,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
    this.isChecked = false,
    this.date,
    this.isTemplate = false,
    this.isSavings = false,
    this.savingsBucket,
    this.isSavingsWithdrawal = false,
  }) : id = id ?? const Uuid().v4();

  Expense createInstance(DateTime instanceDate) {
    return Expense(
      name: name,
      category: category,
      amount: amount,
      frequency: frequency,
      isChecked: true,
      date: instanceDate,
      isTemplate: false,
      isSavings: isSavings, // ✅ Preserve savings flag
      savingsBucket: savingsBucket,
      isSavingsWithdrawal: isSavingsWithdrawal,
    );
  }

  double get weeklyCost => frequency.toWeekly(amount);
  double get fortnightCost => frequency.toFortnight(amount);
}
