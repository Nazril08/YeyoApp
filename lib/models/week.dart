import 'package:hive/hive.dart';

part 'week.g.dart';

@HiveType(typeId: 4)
class Week extends HiveObject {
  @HiveField(0)
  late int weekNumber;

  // This will store Hive keys of the associated Note objects
  @HiveField(1)
  late List<dynamic> noteKeys;

  Week() {
    noteKeys = [];
  }
} 