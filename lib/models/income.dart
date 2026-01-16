import 'package:hive/hive.dart';
import 'frequency.dart';
import 'package:uuid/uuid.dart';

part 'income.g.dart'; // Required for generated adapter

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

  Income({
    String? id,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
  }) : id = id ?? const Uuid().v4();

  /// Weekly amount based on frequency
  double get weeklyAmount => frequency.toWeekly(amount);

  /// Fortnight amount based on frequency
  double get fortnightAmount => frequency.toFortnight(amount);

  /// Convert to map (optional, still useful for JSON)
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'amount': amount,
        'frequency': frequency.index,
      };

  /// Create Income from map
  factory Income.fromMap(Map<String, dynamic> map) => Income(
        id: map['id'],
        name: map['name'],
        category: map['category'],
        amount: map['amount'],
        frequency: Frequency.values[map['frequency']],
      );
}
