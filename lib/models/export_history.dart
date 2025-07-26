import 'package:hive/hive.dart';

part 'export_history.g.dart';

@HiveType(typeId: 6)
class ExportHistory extends HiveObject {
  @HiveField(0)
  late String pdfFileName;

  @HiveField(1)
  late String pdfFilePath;

  @HiveField(2)
  late String courseName;

  @HiveField(3)
  late int weekNumber;
  
  @HiveField(4)
  late DateTime exportDate;
} 