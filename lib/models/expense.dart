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
  String category; // mutable so can reassign if category deleted

  @HiveField(3)
  double amount;

  @HiveField(4)
  Frequency frequency;

  Expense({
    String? id,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
  }) : id = id ?? const Uuid().v4();

  /// Weekly amount
  double get weeklyCost => frequency.toWeekly(amount);

  /// Fortnight amount
  double get fortnightCost => frequency.toFortnight(amount);

  /// Convert to map (optional)
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'amount': amount,
        'frequency': frequency.index,
      };

  /// Create Expense from map
  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        category: map['category'] ?? 'Miscellaneous',
        amount: map['amount']?.toDouble() ?? 0.0,
        frequency: Frequency.values[map['frequency'] ?? 0],
      );
}
