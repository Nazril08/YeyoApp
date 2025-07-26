import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:yeyo/models/course.dart';

class CourseDetailPage extends StatefulWidget {
  final Course? course;
  final dynamic courseKey;

  const CourseDetailPage({super.key, this.course, this.courseKey});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late final Box<Course> _courseBox;
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _lecturerController;
  late final TextEditingController _classNameController;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.course != null;
    _courseBox = Hive.box('courses');

    _nameController = TextEditingController(text: _isEditing ? widget.course!.name : '');
    _lecturerController = TextEditingController(text: _isEditing ? widget.course!.lecturer ?? '' : '');
    _classNameController = TextEditingController(text: _isEditing ? widget.course!.className ?? '' : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lecturerController.dispose();
    _classNameController.dispose();
    super.dispose();
  }

  void _saveCourse() {
    if (_formKey.currentState!.validate()) {
      final newCourse = Course()
        ..name = _nameController.text
        ..lecturer = _lecturerController.text
        ..className = _classNameController.text
        ..weekKeys = _isEditing ? widget.course!.weekKeys : [];

      if (_isEditing) {
        _courseBox.put(widget.courseKey, newCourse);
      } else {
        _courseBox.add(newCourse);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah'),
        backgroundColor: const Color(0xFF1C1C2A),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCourse,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Nama Mata Kuliah',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama mata kuliah tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _lecturerController,
                labelText: 'Nama Dosen (Opsional)',
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _classNameController,
                labelText: 'Kelas (Opsional)',
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF121212),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: const Color(0xFF2C2C44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
} 