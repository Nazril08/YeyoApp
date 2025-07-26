// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NovelAdapter extends TypeAdapter<Novel> {
  @override
  final int typeId = 0;

  @override
  Novel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Novel()
      ..title = fields[0] as String
      ..imageUrl = fields[1] as String
      ..status = fields[2] as String
      ..notes = fields[3] as String
      ..isFavorite = fields[4] as bool
      ..baseUrls = (fields[5] as List).cast<String>()
      ..lastChapterUrls = (fields[6] as List).cast<String>()
      ..synopsis = fields[7] as String?
      ..genres = fields[8] as String?;
  }

  @override
  void write(BinaryWriter writer, Novel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.imageUrl)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.isFavorite)
      ..writeByte(5)
      ..write(obj.baseUrls)
      ..writeByte(6)
      ..write(obj.lastChapterUrls)
      ..writeByte(7)
      ..write(obj.synopsis)
      ..writeByte(8)
      ..write(obj.genres);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NovelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
