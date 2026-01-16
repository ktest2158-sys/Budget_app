import '../models/income.dart';
import '../models/expense.dart';
import '../models/frequency.dart';

final incomes = <Income>[
  Income(name: 'Asif', amount: 1500, frequency: Frequency.fortnightly),
  Income(name: 'Kara', amount: 0, frequency: Frequency.weekly),
];

final expenses = <Expense>[
  Expense(name: 'Groceries', amount: 250, frequency: Frequency.weekly),
  Expense(name: 'Fuel', amount: 120, frequency: Frequency.weekly),
  Expense(name: 'Phone', amount: 80, frequency: Frequency.monthly),
  Expense(name: 'Electricity', amount: 600, frequency: Frequency.quarterly),
  Expense(name: 'Car Rego', amount: 900, frequency: Frequency.annual),
];
