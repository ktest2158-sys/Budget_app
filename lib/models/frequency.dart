import 'package:hive/hive.dart';

part 'frequency.g.dart';

@HiveType(typeId: 2) // unique typeId
enum Frequency {
  @HiveField(0)
  weekly,

  @HiveField(1)
  fortnightly,

  @HiveField(2)
  monthly,

  @HiveField(3)
  quarterly,

  @HiveField(4)
  annual,
}

/// Extension methods for Frequency
extension FrequencyExtension on Frequency {
  double toWeekly(double amount) {
    switch (this) {
      case Frequency.weekly:
        return amount;
      case Frequency.fortnightly:
        return amount / 2;
      case Frequency.monthly:
        return amount / 4.345;
      case Frequency.quarterly:
        return amount / (4.345 * 3);
      case Frequency.annual:
        return amount / 52.1429;
    }
  }

  double toFortnight(double amount) {
    switch (this) {
      case Frequency.weekly:
        return amount * 2;
      case Frequency.fortnightly:
        return amount;
      case Frequency.monthly:
        return amount * (14 / 30);
      case Frequency.quarterly:
        return amount * (14 / 90);
      case Frequency.annual:
        return amount * (14 / 365);
    }
  }

  String get label => name[0].toUpperCase() + name.substring(1);
}
