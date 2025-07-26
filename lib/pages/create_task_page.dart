import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:yeyo/models/todo.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateTaskPage extends StatefulWidget {
  final Todo? todoToEdit;
  final dynamic todoKey;
  const CreateTaskPage({super.key, this.todoToEdit, this.todoKey});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final Box<Todo> _todoBox;
  late bool _isEditing;
  List<String> _photoPaths = [];

  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _todoBox = Hive.box('todos');
    _isEditing = widget.todoToEdit != null;

    if (_isEditing) {
      _titleController.text = widget.todoToEdit!.title;
      _descriptionController.text = widget.todoToEdit!.description ?? '';
      _rangeStart = widget.todoToEdit!.startDate;
      _rangeEnd = widget.todoToEdit!.endDate;
      _photoPaths = widget.todoToEdit!.photoPaths ?? [];
      if (_rangeStart != null) {
        _focusedDay = _rangeStart!;
      }
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      // When a new end date is selected, set a default end-of-day time.
      if (end != null) {
        _rangeEnd = DateTime(end.year, end.month, end.day, 23, 59);
      }
    });
  }

  Future<void> _selectEndTime() async {
    if (_rangeEnd == null) return;
    final initialTime = TimeOfDay.fromDateTime(_rangeEnd!);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        _rangeEnd = DateTime(
          _rangeEnd!.year,
          _rangeEnd!.month,
          _rangeEnd!.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _saveTask() {
    if (_titleController.text.isEmpty) {
      // Maybe show a snackbar or alert
      return;
    }

    final task = Todo()
      ..title = _titleController.text
      ..description = _descriptionController.text
      ..startDate = _rangeStart
      ..endDate = _rangeEnd
      ..photoPaths = _photoPaths
      ..isCompleted = _isEditing ? widget.todoToEdit!.isCompleted : false;

    if (_isEditing) {
      _todoBox.put(widget.todoKey, task);
    } else {
      _todoBox.add(task);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Update Task' : 'Create New Task',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(isDarkMode),
            const SizedBox(height: 20),
            _buildDateDisplay(isDarkMode),
            const SizedBox(height: 20),
            _buildTextField(
                label: 'Title',
                controller: _titleController,
                isDarkMode: isDarkMode),
            const SizedBox(height: 20),
            _buildTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
                isDarkMode: isDarkMode),
            const SizedBox(height: 20),
            _buildPhotoSection(isDarkMode),
            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(bool isDarkMode) {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime.utc(2010, 1, 1),
      lastDay: DateTime.utc(2040, 12, 31),
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      onRangeSelected: _onRangeSelected,
      rangeSelectionMode: RangeSelectionMode.toggledOn,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle:
            TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18),
        leftChevronIcon:
            Icon(Icons.chevron_left, color: isDarkMode ? Colors.white : Colors.black),
        rightChevronIcon:
            Icon(Icons.chevron_right, color: isDarkMode ? Colors.white : Colors.black),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        weekendTextStyle:
            TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        todayDecoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        rangeStartDecoration: const BoxDecoration(
          color: Color(0xFF6E5DE7),
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: const BoxDecoration(
          color: Color(0xFF6E5DE7),
          shape: BoxShape.circle,
        ),
        rangeHighlightColor: Colors.purple.withOpacity(0.2),
        withinRangeTextStyle: const TextStyle(color: Colors.white),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        weekendStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
      ),
    );
  }

  Widget _buildDateDisplay(bool isDarkMode) {
    if (_rangeStart == null) return const SizedBox.shrink();

    final dayFormat = DateFormat('dd MMM, yyyy');
    final timeFormat = DateFormat('HH:mm');

    String dateText = dayFormat.format(_rangeStart!);
    if (_rangeEnd != null && _rangeEnd != _rangeStart) {
      dateText += ' - ${dayFormat.format(_rangeEnd!)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined,
              color: isDarkMode ? Colors.white70 : Colors.black54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(dateText,
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500)),
          ),
          if (_rangeEnd != null) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: _selectEndTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 18, color: Color(0xFF6E5DE7)),
                    const SizedBox(width: 6),
                    Text(
                      timeFormat.format(_rangeEnd!),
                      style: const TextStyle(
                          color: Color(0xFF6E5DE7),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      int? maxLines = 1,
      required bool isDarkMode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    setState(() {
      _photoPaths.addAll(pickedFiles.map((x) => x.path));
    });
  }

  Widget _buildPhotoSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _photoPaths.length + 1,
            itemBuilder: (context, index) {
              if (index == _photoPaths.length) {
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: Colors.white70),
                  ),
                );
              }
              final path = _photoPaths[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _photoPaths.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E5DE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_isEditing ? 'Update' : 'Save', style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
} 