// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExportHistoryAdapter extends TypeAdapter<ExportHistory> {
  @override
  final int typeId = 6;

  @override
  ExportHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExportHistory()
      ..pdfFileName = fields[0] as String
      ..pdfFilePath = fields[1] as String
      ..courseName = fields[2] as String
      ..weekNumber = fields[3] as int
      ..exportDate = fields[4] as DateTime;
  }

  @override
  void write(BinaryWriter writer, ExportHistory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.pdfFileName)
      ..writeByte(1)
      ..write(obj.pdfFilePath)
      ..writeByte(2)
      ..write(obj.courseName)
      ..writeByte(3)
      ..write(obj.weekNumber)
      ..writeByte(4)
      ..write(obj.exportDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
