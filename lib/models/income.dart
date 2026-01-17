import 'package:hive/hive.dart';
import 'frequency.dart';
import 'package:uuid/uuid.dart';

part 'income.g.dart';

@HiveType(typeId: 0)
class Income extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final Frequency frequency;

  // ✅ NEW: This allows the dashboard to filter income by fortnight
  @HiveField(5)
  DateTime date;

  Income({
    String? id,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
    DateTime? date, // ✅ Added to constructor
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now(); // ✅ Defaults to now

  double get weeklyAmount => frequency.toWeekly(amount);
  double get fortnightAmount => frequency.toFortnight(amount);
}