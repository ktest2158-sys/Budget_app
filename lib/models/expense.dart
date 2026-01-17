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

  // ✅ Used to filter which fortnight this payment belongs to
  @HiveField(6)
  DateTime? date;

  // ✅ Used to identify items in your "Master List"
  @HiveField(7)
  bool isTemplate;

  Expense({
    String? id,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
    this.isChecked = false,
    this.date,
    this.isTemplate = false,
  }) : id = id ?? const Uuid().v4();

  // Helper to create a "Real" expense payment record from a master template
  Expense createInstance(DateTime instanceDate) {
    return Expense(
      name: name,
      category: category,
      amount: amount,
      frequency: frequency,
      isChecked: true, // It is checked because we are creating it by checking it off
      date: instanceDate,
      isTemplate: false, // This is a real record, not a template
    );
  }

  double get weeklyCost => frequency.toWeekly(amount);
  double get fortnightCost => frequency.toFortnight(amount);
}