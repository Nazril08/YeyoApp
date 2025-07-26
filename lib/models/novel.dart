import 'package:hive/hive.dart';

part 'novel.g.dart';

@HiveType(typeId: 0)
class Novel extends HiveObject {
  Novel();

  @HiveField(0)
  late String title;

  @HiveField(1)
  late String imageUrl;

  @HiveField(2)
  late String status;

  @HiveField(3)
  late String notes;

  @HiveField(4)
  bool isFavorite = false;

  @HiveField(5)
  List<String> baseUrls = [];

  @HiveField(6)
  List<String> lastChapterUrls = [];

  @HiveField(7)
  String? synopsis;

  @HiveField(8)
  String? genres;

  Map<String, dynamic> toJson() => {
        'title': title,
        'imageUrl': imageUrl,
        'status': status,
        'notes': notes,
        'isFavorite': isFavorite,
        'baseUrls': baseUrls,
        'lastChapterUrls': lastChapterUrls,
        'synopsis': synopsis,
        'genres': genres,
      };

  factory Novel.fromJson(Map<String, dynamic> json) {
    return Novel()
      ..title = json['title']
      ..imageUrl = json['imageUrl']
      ..status = json['status']
      ..notes = json['notes'] ?? ''
      ..isFavorite = json['isFavorite'] ?? false
      ..baseUrls = json['baseUrls'] != null 
          ? List<String>.from(json['baseUrls']) 
          : (json['baseUrl'] != null ? [json['baseUrl']] : [])
      ..lastChapterUrls = json['lastChapterUrls'] != null 
          ? List<String>.from(json['lastChapterUrls'])
          : (json['lastChapterUrl'] != null ? [json['lastChapterUrl']] : [])
      ..synopsis = json['synopsis']
      ..genres = json['genres'];
  }
} 