import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'bookmark.g.dart';

@HiveType(typeId: 8)
class Bookmark extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String url;

  @HiveField(3)
  late String category;

  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  late String? imageUrl;

  Bookmark({
    String? id,
    required this.title,
    required this.url,
    required this.category,
    DateTime? createdAt,
    this.imageUrl,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
} 