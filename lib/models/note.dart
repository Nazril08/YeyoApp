import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 5)
class Note extends HiveObject {
  // 'text' or 'image'
  @HiveField(0)
  late String type;

  // content if type is 'text', file path if type is 'image'
  @HiveField(1)
  late String content;

  @HiveField(2)
  late DateTime createdAt;
} 