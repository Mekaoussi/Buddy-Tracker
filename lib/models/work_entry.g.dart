// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkEntryAdapter extends TypeAdapter<WorkEntry> {
  @override
  final int typeId = 0;

  @override
  WorkEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkEntry(
      date: fields[0] as DateTime,
      morningEntry: fields[1] as DateTime?,
      morningExit: fields[2] as DateTime?,
      afternoonEntry: fields[3] as DateTime?,
      afternoonExit: fields[4] as DateTime?,
      notes: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WorkEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.morningEntry)
      ..writeByte(2)
      ..write(obj.morningExit)
      ..writeByte(3)
      ..write(obj.afternoonEntry)
      ..writeByte(4)
      ..write(obj.afternoonExit)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
