import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  String? fullName;

  @HiveField(1)
  String? npm;

  @HiveField(2)
  String? className;
} 