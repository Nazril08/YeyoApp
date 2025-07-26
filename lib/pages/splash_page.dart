import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yeyo/models/app_settings.dart';
import 'package:yeyo/models/bookmark.dart';
import 'package:yeyo/models/course.dart';
import 'package:yeyo/models/export_history.dart';
import 'package:yeyo/models/note.dart';
import 'package:yeyo/models/novel.dart';
import 'package:yeyo/models/novel_settings.dart';
import 'package:yeyo/models/todo.dart';
import 'package:yeyo/models/week.dart';
import 'package:yeyo/pages/main_dashboard_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupApplication();
  }

  Future<void> _precacheNovelImages() async {
    if (!mounted) return;
    setState(() {
      _loadingMessage = 'Pre-loading ';
    });

    final novelBox = Hive.box<Novel>('novels');
    final novels = novelBox.values.toList();
    int precachedCount = 0;

    for (final novel in novels) {
      if (novel.imageUrl.startsWith('http')) {
        try {
          // Using CachedNetworkImageProvider to leverage the existing cache
          await precacheImage(
            CachedNetworkImageProvider(novel.imageUrl),
            context,
            onError: (e, stackTrace) {
              // Optionally log errors, but don't stop the process
              debugPrint('Failed to precache image: ${novel.imageUrl}, Error: $e');
            },
          );
          precachedCount++;
          if (mounted) {
            setState(() {
              _loadingMessage = 'Loading covers: $precachedCount/${novels.length}';
            });
          }
        } catch (e) {
          debugPrint('Error during precaching image ${novel.imageUrl}: $e');
        }
      }
    }
  }

  Future<void> _setupApplication() async {
    // Initialize Hive and open boxes
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    Hive.registerAdapter(NovelAdapter());
    Hive.registerAdapter(TodoAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(CourseAdapter());
    Hive.registerAdapter(WeekAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(ExportHistoryAdapter());
    Hive.registerAdapter(NovelSettingsAdapter());
    Hive.registerAdapter(BookmarkAdapter());
    await Hive.openBox<Novel>('novels');
    await Hive.openBox<Todo>('todos');
    await Hive.openBox<AppSettings>('settings');
    await Hive.openBox<Course>('courses');
    await Hive.openBox<Week>('weeks');
    await Hive.openBox<Note>('notes');
    await Hive.openBox<ExportHistory>('export_history');
    await Hive.openBox<NovelSettings>('novel_settings');
    await Hive.openBox<Bookmark>('bookmarks');

    // Pre-cache images after loading data
    await _precacheNovelImages();

    // Simulate a delay for splash screen visibility
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate to the main dashboard
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainDashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_loadingMessage),
          ],
        ),
      ),
    );
  }
} 