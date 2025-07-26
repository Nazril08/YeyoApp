import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yeyo/models/app_settings.dart';
import 'package:yeyo/pages/export_history_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Box<AppSettings> _settingsBox;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _npmController;
  late final TextEditingController _classNameController;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    // Load existing settings. We use a fixed key (0) because there's only one settings object.
    final settings = _settingsBox.get(0, defaultValue: AppSettings());

    _fullNameController = TextEditingController(text: settings?.fullName ?? '');
    _npmController = TextEditingController(text: settings?.npm ?? '');
    _classNameController = TextEditingController(text: settings?.className ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _npmController.dispose();
    _classNameController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final newSettings = AppSettings()
        ..fullName = _fullNameController.text
        ..npm = _npmController.text
        ..className = _classNameController.text;

      _settingsBox.put(0, newSettings);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data untuk Nama File PDF',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Informasi ini akan digunakan untuk format nama file default: Nama_NPM_Kelas.pdf',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _fullNameController,
                labelText: 'Nama Lengkap',
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _npmController,
                labelText: 'NPM',
                 validator: (value) => value == null || value.isEmpty ? 'NPM tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _classNameController,
                labelText: 'Kelas',
                 validator: (value) => value == null || value.isEmpty ? 'Kelas tidak boleh kosong' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Lihat Riwayat Ekspor'),
                  onPressed: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExportHistoryPage()),
                    );
                  },
                   style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF6E5DE7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Pengaturan'),
                  onPressed: _saveSettings,
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