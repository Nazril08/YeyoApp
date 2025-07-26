import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeyo/models/note.dart';
import 'package:yeyo/services/gemini_service.dart';
import 'package:yeyo/widgets/api_key_dialog.dart';

class NoteEditPage extends StatefulWidget {
  final Note? note;

  const NoteEditPage({super.key, this.note});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _textController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  late bool _isEditing;
  bool _isLoading = false;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    if (_isEditing) {
      _textController.text = widget.note!.content;
    }
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString(apiKeyStorageKey);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_textController.text.isNotEmpty) {
      Navigator.pop(context, _textController.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan tidak boleh kosong.')),
      );
    }
  }

  Future<void> _improveNoteWithAI() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada teks untuk diperbaiki.')),
      );
      return;
    }

    String? currentApiKey = _apiKey;
    if (currentApiKey == null || currentApiKey.isEmpty) {
      final newApiKey = await showApiKeyDialog(context);
      if (newApiKey == null || newApiKey.isEmpty) {
        // User cancelled or entered an empty key
        return;
      }
      setState(() {
        _apiKey = newApiKey;
      });
      currentApiKey = newApiKey;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final improvedText = await _geminiService.improveText(
        apiKey: currentApiKey!,
        text: _textController.text,
      );
      _textController.text = improvedText;
    } catch (e) {
      if (!mounted) return;

      if (e is InvalidApiKeyException) {
        // Clear the invalid key from storage and state
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(apiKeyStorageKey);
        setState(() {
          _apiKey = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );

        // Prompt for a new key
        final newApiKey = await showApiKeyDialog(context);
        if (newApiKey != null && newApiKey.isNotEmpty) {
          setState(() {
            _apiKey = newApiKey;
          });
          // User can now retry by pressing the button again.
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Catatan' : 'Tambah Catatan Teks'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _isLoading ? null : _improveNoteWithAI,
            tooltip: 'Perbaiki dengan AI',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveNote,
            tooltip: 'Simpan Catatan',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _textController,
          autofocus: true,
              maxLines: null,
              expands: true,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: 'Tulis catatan Anda di sini...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
} 