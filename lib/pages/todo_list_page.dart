import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yeyo/models/todo.dart';
import 'package:yeyo/pages/create_task_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  late final Box<Todo> _todoBox;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _todoBox = Hive.box('todos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Tasks',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _todoBox.listenable(),
              builder: (context, Box<Todo> box, _) {
                final allTodos = box.values.toList().cast<Todo>();
                final filteredTodos = allTodos.where((todo) {
                  return todo.title
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredTodos.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = filteredTodos[index];
                    final todoKey = box.keyAt(allTodos.indexOf(todo));
                    return _buildTaskCard(context, todo, todoKey);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTaskPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search recent task',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Todo todo, dynamic todoKey) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: todo.isCompleted,
                onChanged: (bool? value) {
                  final updatedTodo = todo..isCompleted = value!;
                  updatedTodo.save();
                },
                activeColor: Theme.of(context).primaryColor,
                checkColor: Colors.white,
                side: BorderSide(color: Colors.white54, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: todo.isCompleted ? Colors.grey : Colors.white,
                      decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (todo.description != null && todo.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        todo.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: todo.isCompleted ? Colors.grey : Colors.white70,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (todo.startDate != null) _buildDateChip(todo),
                  if (todo.photoPaths != null && todo.photoPaths!.isNotEmpty)
                    _buildPhotoGallery(todo.photoPaths!),
                ],
              ),
            ),
            Builder(
              builder: (BuildContext iconButtonContext) {
                return IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () =>
                      _showOptionsMenu(iconButtonContext, todo, todoKey),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> paths) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: paths.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(paths[index]),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(width: 50, height: 50, color: Colors.grey.shade300),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, Todo todo, dynamic todoKey) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit task'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: const ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.redAccent),
            title: Text('Delete task', style: TextStyle(color: Colors.redAccent)),
          ),
        ),
      ],
    ).then((String? value) {
      if (value == null) return;
      if (value == 'edit') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  CreateTaskPage(todoToEdit: todo, todoKey: todoKey)),
        );
      } else if (value == 'delete') {
        _deleteTodo(todo);
      }
    });
  }

  Future<void> _deleteTodo(Todo todo) async {
    await todo.delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildDateChip(Todo todo) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final todoDate = DateTime(todo.startDate!.year, todo.startDate!.month, todo.startDate!.day);

    String dateText;
    Color chipColor;
    Color textColor;

    if (todoDate.isAtSameMomentAs(today)) {
      dateText = 'Today';
      chipColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green.shade200;
    } else if (todoDate.isAtSameMomentAs(tomorrow)) {
      dateText = 'Tomorrow';
      chipColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange.shade200;
    } else {
      dateText = DateFormat.yMMMd().format(todo.startDate!);
      chipColor = Theme.of(context).primaryColor.withOpacity(0.2);
      textColor = Theme.of(context).primaryColor;
    }

    return Chip(
      label: Text(dateText, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text(
            'No tasks yet!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Add a task to get started.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
