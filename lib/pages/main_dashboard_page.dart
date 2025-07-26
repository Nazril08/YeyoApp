import 'package:flutter/material.dart';
import 'package:yeyo/pages/bookmark_manager_page.dart';
import 'package:yeyo/pages/course_list_page.dart';
import 'package:yeyo/pages/gemini_settings_page.dart';
import 'package:yeyo/pages/novel_tracker_page.dart';
import 'package:yeyo/pages/search_page.dart';
import 'package:yeyo/pages/todo_list_page.dart';
import 'package:yeyo/pages/tools_page.dart';

class MainDashboardPage extends StatelessWidget {
  MainDashboardPage({super.key});

  final List<SearchableFeature> _features = [
    SearchableFeature(
      title: 'Novel Tracker',
      description: 'Track your reading progress.',
      page: const NovelTrackerPage(),
    ),
    SearchableFeature(
      title: 'To-Do List',
      description: 'Manage your daily tasks.',
      page: const TodoListPage(),
    ),
    SearchableFeature(
      title: 'Bookmark Manager',
      description: 'Save and organize your links.',
      page: const BookmarkManagerPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yeyo',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            iconSize: 28.0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GeminiSettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: 28.0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage(allFeatures: _features)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildRecentGrid(context),
      ),
    );
  }

  Widget _buildRecentGrid(BuildContext context) {
    final recentItems = [
      {
        'title': 'Novel',
        'color': const Color(0xFF2D9C8A),
        'category': 'Notes',
        'icon': Icons.headphones,
        'page': const NovelTrackerPage(),
      },
      {
        'title': 'To-Do List',
        'color': const Color(0xFFEB5757),
        'category': 'Tasks',
        'icon': Icons.check_circle,
        'page': const TodoListPage(),
      },
      {
        'title': 'Catatan Kuliah',
        'color': const Color(0xFF2F80ED),
        'category': 'Lecture',
        'icon': Icons.school,
        'page': const CourseListPage(),
      },
      {
        'title': 'Bookmark Manager',
        'color': const Color(0xFF8A57EB),
        'category': 'Links',
        'icon': Icons.bookmark,
        'page': const BookmarkManagerPage(),
      },
      {
        'title': 'Tools',
        'color': Colors.grey,
        'category': 'Utilities',
        'icon': Icons.build,
        'page': const ToolsPage(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: recentItems.length,
      itemBuilder: (context, index) {
        final item = recentItems[index];
        return GestureDetector(
          onTap: () {
            if (item['page'] != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => item['page'] as Widget));
            }
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            shadowColor: Colors.black.withOpacity(0.15),
            color: item['color'] as Color,
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Positioned(
                  bottom: -15,
                  right: -15,
                  child: Icon(
                    item['icon'] as IconData,
                    size: 90,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['category'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 