import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yeyo/models/course.dart';
import 'package:yeyo/models/week.dart';
import 'package:yeyo/pages/course_detail_page.dart';
import 'package:yeyo/pages/note_list_page.dart';

class WeekListPage extends StatefulWidget {
  final Course course;
  final dynamic courseKey;

  const WeekListPage({super.key, required this.course, required this.courseKey});

  @override
  State<WeekListPage> createState() => _WeekListPageState();
}

class _WeekListPageState extends State<WeekListPage> {
  late final Box<Week> _weekBox;
  late final Box<Course> _courseBox;

  @override
  void initState() {
    super.initState();
    _weekBox = Hive.box('weeks');
    _courseBox = Hive.box('courses');
  }

  void _addWeek() {
    final newWeekNumber = widget.course.weekKeys.length + 1;
    final newWeek = Week()..weekNumber = newWeekNumber;

    // Save the new week and get its key
    _weekBox.add(newWeek).then((weekKey) {
      // Add the new week's key to the course's weekKeys list
      final course = _courseBox.get(widget.courseKey);
      if (course != null) {
        course.weekKeys.add(weekKey);
        course.save(); // Save the updated course
      }
    });
  }
  
  void _deleteWeek(dynamic weekKey) {
    // Also remove the key from the course's list
    final course = _courseBox.get(widget.courseKey);
    if (course != null) {
      course.weekKeys.remove(weekKey);
      course.save();
    }
    _weekBox.delete(weekKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.course.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            Text(
              '${widget.course.lecturer?.isNotEmpty == true ? widget.course.lecturer : "Dosen: -"}',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailPage(
                    course: widget.course,
                    courseKey: widget.courseKey,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _courseBox.listenable(keys: [widget.courseKey]),
        builder: (context, Box<Course> box, _) {
          final course = box.get(widget.courseKey);
          if (course == null || course.weekKeys.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.calendar_view_week_outlined, size: 80, color: Colors.white30),
                   SizedBox(height: 16),
                  Text(
                    'Belum ada minggu yang ditambahkan.',
                     style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                   Text(
                    'Tekan tombol + untuk memulai',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: course.weekKeys.length,
            itemBuilder: (context, index) {
              final weekKey = course.weekKeys[index];
              final week = _weekBox.get(weekKey) as Week;
              return _buildWeekCard(context, week, weekKey, course);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWeek,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Minggu',
        backgroundColor: Colors.deepPurpleAccent,
      ),
      backgroundColor: const Color(0xFF1A1A2E),
    );
  }

  Widget _buildWeekCard(BuildContext context, Week week, dynamic weekKey, Course course) {
    return GestureDetector(
       onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoteListPage(
              course: course,
              week: week,
              weekKey: weekKey,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E48),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${week.weekNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Minggu ${week.weekNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              onPressed: () => _deleteWeek(weekKey),
            ),
          ],
        ),
      ),
    );
  }
} 