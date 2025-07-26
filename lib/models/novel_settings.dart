import 'package:hive/hive.dart';

part 'novel_settings.g.dart';

@HiveType(typeId: 7)
class NovelSettings extends HiveObject {
  // Fields for novel settings will go here.
  // For now, we can leave it empty or add a placeholder.
  @HiveField(0)
  String? placeholder;
} 