// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeekAdapter extends TypeAdapter<Week> {
  @override
  final int typeId = 4;

  @override
  Week read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Week()
      ..weekNumber = fields[0] as int
      ..noteKeys = (fields[1] as List).cast<dynamic>();
  }

  @override
  void write(BinaryWriter writer, Week obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.weekNumber)
      ..writeByte(1)
      ..write(obj.noteKeys);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
