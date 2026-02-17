// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 1;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String?,
      name: fields[1] as String,
      category: fields[2] as String,
      amount: fields[3] as double,
      frequency: fields[4] as Frequency,
      isChecked: fields[5] as bool,
      date: fields[6] as DateTime?,
      isTemplate: fields[7] as bool,
      isSavings: fields[8] as bool,
      savingsBucket: fields[9] as String?,
      isSavingsWithdrawal: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.isChecked)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.isTemplate)
      ..writeByte(8)
      ..write(obj.isSavings)
      ..writeByte(9)
      ..write(obj.savingsBucket)
      ..writeByte(10)
      ..write(obj.isSavingsWithdrawal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
