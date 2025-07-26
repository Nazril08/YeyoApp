import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String apiKeyStorageKey = 'gemini_api_key';

Future<String?> showApiKeyDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const ApiKeyDialog(),
  );
}

class ApiKeyDialog extends StatefulWidget {
  const ApiKeyDialog({super.key});

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  final _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text;
    if (apiKey.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(apiKeyStorageKey, apiKey);
      if (mounted) {
        Navigator.pop(context, apiKey);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key tidak boleh kosong.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Masukkan Gemini API Key'),
      content: TextField(
        controller: _apiKeyController,
        decoration: const InputDecoration(
          hintText: 'API Key Anda',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saveApiKey,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
} 