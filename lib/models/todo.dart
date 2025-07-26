import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 1)
class Todo extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late bool isCompleted;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? startDate;

  @HiveField(4)
  DateTime? endDate;

  @HiveField(5)
  List<String>? photoPaths;

  @HiveField(6)
  DateTime? createdAt;
} 