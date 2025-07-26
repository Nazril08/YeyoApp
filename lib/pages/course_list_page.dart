import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yeyo/models/course.dart';
import 'package:yeyo/pages/course_detail_page.dart';
import 'package:yeyo/pages/settings_page.dart';
import 'package:yeyo/pages/week_list_page.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({super.key});

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  late final Box<Course> _courseBox;

  @override
  void initState() {
    super.initState();
    _courseBox = Hive.box('courses');
  }

  void _deleteCourse(dynamic key) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Mata Kuliah'),
          content: const Text(
              'Apakah Anda yakin ingin menghapus mata kuliah ini? Semua data di dalamnya akan ikut terhapus.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _courseBox.delete(key);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mata Kuliah',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            iconSize: 28.0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _courseBox.listenable(),
        builder: (context, Box<Course> box, _) {
          if (box.values.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada mata kuliah',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tekan tombol + untuk memulai',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final course = box.getAt(index)!;
              final courseKey = box.keyAt(index);
              return _buildCourseCard(context, course, courseKey);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CourseDetailPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, dynamic courseKey) {
    final iconData = _getIconForCourse(course.name);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WeekListPage(course: course, courseKey: courseKey),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(iconData, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${course.lecturer?.isNotEmpty == true ? course.lecturer : "Dosen: -"}  •  ${course.className?.isNotEmpty == true ? course.className : "Kelas: -"}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                onPressed: () => _deleteCourse(courseKey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCourse(String courseName) {
    final icons = [
      Icons.computer,
      Icons.architecture,
      Icons.calculate,
      Icons.science_outlined,
      Icons.history_edu,
      Icons.psychology,
      Icons.language,
      Icons.local_library,
    ];
    final index = courseName.hashCode % icons.length;
    return icons[index];
  }
} 