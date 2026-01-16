import 'package:hive/hive.dart';
import 'frequency.dart';
import 'package:uuid/uuid.dart';

part 'expense.g.dart'; // Required for generated adapter

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

  // ✅ New field added safely at index 5
  @HiveField(5)
  bool isChecked;

  Expense({
    String? id,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
    this.isChecked = false, // ✅ Default value prevents data loss on old records
  }) : id = id ?? const Uuid().v4();

  /// Weekly amount
  double get weeklyCost => frequency.toWeekly(amount);

  /// Fortnight amount
  double get fortnightCost => frequency.toFortnight(amount);

  /// Convert to map
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'amount': amount,
        'frequency': frequency.index,
        'isChecked': isChecked,
      };

  /// Create Expense from map
  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        category: map['category'] ?? 'Miscellaneous',
        amount: map['amount']?.toDouble() ?? 0.0,
        frequency: Frequency.values[map['frequency'] ?? 0],
        isChecked: map['isChecked'] ?? false,
      );
}
