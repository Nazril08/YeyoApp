// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseAdapter extends TypeAdapter<Course> {
  @override
  final int typeId = 3;

  @override
  Course read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Course()
      ..name = fields[0] as String
      ..lecturer = fields[1] as String?
      ..className = fields[2] as String?
      ..weekKeys = (fields[3] as List).cast<dynamic>();
  }

  @override
  void write(BinaryWriter writer, Course obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.lecturer)
      ..writeByte(2)
      ..write(obj.className)
      ..writeByte(3)
      ..write(obj.weekKeys);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
