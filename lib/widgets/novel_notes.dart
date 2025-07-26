import 'package:flutter/material.dart';
import '../models/novel.dart';

class NovelNotes extends StatefulWidget {
  final Novel novel;
  final Function(Novel) onNovelUpdated;

  const NovelNotes({
    Key? key,
    required this.novel,
    required this.onNovelUpdated,
  }) : super(key: key);

  @override
  State<NovelNotes> createState() => _NovelNotesState();
}

class _NovelNotesState extends State<NovelNotes> {
  final TextEditingController _noteController = TextEditingController();
  List<String> _notesList = [];

  @override
  void initState() {
    super.initState();
    if (widget.novel.notes.isNotEmpty) {
      _notesList = widget.novel.notes.split('\n');
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _addNote() {
    if (_noteController.text.trim().isNotEmpty) {
      setState(() {
        _notesList.add(_noteController.text.trim());
        widget.novel.notes = _notesList.join('\n');
        widget.novel.save();
        widget.onNovelUpdated(widget.novel);
        _noteController.clear();
      });
    }
  }

  void _removeNote(int index) {
    setState(() {
      _notesList.removeAt(index);
      widget.novel.notes = _notesList.join('\n');
      widget.novel.save();
      widget.onNovelUpdated(widget.novel);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Notes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Add your personal notes...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addNote,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_notesList.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _notesList.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    title: Text(_notesList[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeNote(index),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
} 