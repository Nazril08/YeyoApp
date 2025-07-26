import 'package:hive/hive.dart';

part 'course.g.dart';

@HiveType(typeId: 3)
class Course extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  String? lecturer;

  @HiveField(2)
  String? className;

  // This will store Hive keys of the associated Week objects
  @HiveField(3)
  late List<dynamic> weekKeys;

  Course() {
    weekKeys = [];
  }
} 