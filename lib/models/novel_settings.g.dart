// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NovelSettingsAdapter extends TypeAdapter<NovelSettings> {
  @override
  final int typeId = 7;

  @override
  NovelSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NovelSettings()..placeholder = fields[0] as String?;
  }

  @override
  void write(BinaryWriter writer, NovelSettings obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.placeholder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NovelSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
