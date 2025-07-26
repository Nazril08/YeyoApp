import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeyo/widgets/api_key_dialog.dart'; // Using the constant from here

class GeminiSettingsPage extends StatefulWidget {
  const GeminiSettingsPage({super.key});

  @override
  State<GeminiSettingsPage> createState() => _GeminiSettingsPageState();
}

class _GeminiSettingsPageState extends State<GeminiSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _apiKeyController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    _apiKeyController.text = prefs.getString(apiKeyStorageKey) ?? '';
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(apiKeyStorageKey, _apiKeyController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Gemini'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Key untuk Gemini',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'API Key ini dibutuhkan untuk fitur AI. Anda bisa mendapatkannya dari Google AI Studio.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _apiKeyController,
                      validator: (value) => value == null || value.isEmpty
                          ? 'API Key tidak boleh kosong'
                          : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Gemini API Key',
                        labelStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        filled: true,
                        fillColor: const Color(0xFF2C2C44),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan API Key'),
                        onPressed: _saveApiKey,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF6E5DE7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
      backgroundColor: const Color(0xFF1A1A2E),
    );
  }
} 