import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bookmark.dart';

class AddEditBookmarkPage extends StatefulWidget {
  final Bookmark? bookmark;
  const AddEditBookmarkPage({super.key, this.bookmark});

  @override
  State<AddEditBookmarkPage> createState() => _AddEditBookmarkPageState();
}

class _AddEditBookmarkPageState extends State<AddEditBookmarkPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String? _imageFilePath;

  List<String> _allCategories = [];

  bool get _isEditing => widget.bookmark != null;
  bool _isUrlImageSource = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (_isEditing) {
      _titleController.text = widget.bookmark!.title;
      _urlController.text = widget.bookmark!.url;
      _categoryController.text = widget.bookmark!.category;
      final imageUrl = widget.bookmark!.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (imageUrl.startsWith('http')) {
          _imageUrlController.text = imageUrl;
          _isUrlImageSource = true;
        } else {
          _imageFilePath = imageUrl;
          _isUrlImageSource = false;
        }
      }
    }
  }

  void _loadCategories() {
    final bookmarkBox = Hive.box<Bookmark>('bookmarks');
    final uniqueCategories = bookmarkBox.values.map((b) => b.category).toSet().toList();
    setState(() {
      _allCategories = uniqueCategories;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFilePath = pickedFile.path;
      });
    }
  }

  void _saveBookmark() {
    if (_formKey.currentState!.validate()) {
      if (_isEditing) {
        widget.bookmark!.title = _titleController.text;
        widget.bookmark!.url = _urlController.text;
        widget.bookmark!.category = _categoryController.text;
        widget.bookmark!.imageUrl = _isUrlImageSource ? _imageUrlController.text : _imageFilePath;
        widget.bookmark!.save();
      } else {
        final bookmarkBox = Hive.box<Bookmark>('bookmarks');
        final newBookmark = Bookmark(
          title: _titleController.text,
          url: _urlController.text,
          category: _categoryController.text,
          imageUrl: _isUrlImageSource ? _imageUrlController.text : _imageFilePath,
        );
        bookmarkBox.add(newBookmark);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F222A),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Bookmark' : 'Add to Vault',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F222A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_titleController, 'Title', isRequired: true),
              const SizedBox(height: 16),
              _buildTextField(_urlController, 'URL', isRequired: true),
              const SizedBox(height: 16),
              _buildCategoryField(),
              const SizedBox(height: 24),
              _buildImageSourceToggle(),
              const SizedBox(height: 16),
              if (_isUrlImageSource)
                _buildTextField(_imageUrlController, 'Image URL (Optional)')
              else
                _buildGalleryPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return _allCategories.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _categoryController.text = selection;
      },
      fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
        // We need to use a separate controller for the Autocomplete's field
        // and sync it with our main category controller.
        fieldController.text = _categoryController.text;
        fieldController.addListener(() {
          _categoryController.text = fieldController.text;
        });

        return TextFormField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Category',
            labelStyle: GoogleFonts.inter(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF2A2D36),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Category is required';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: const Color(0xFF2A2D36),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 32, // Match form field width
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option, style: GoogleFonts.inter(color: Colors.white)),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Image from URL'),
          selected: _isUrlImageSource,
          onSelected: (selected) {
            if (selected) setState(() => _isUrlImageSource = true);
          },
        ),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('Image from Gallery'),
          selected: !_isUrlImageSource,
          onSelected: (selected) {
            if (selected) setState(() => _isUrlImageSource = false);
          },
        ),
      ],
    );
  }

  Widget _buildGalleryPicker() {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D36),
            borderRadius: BorderRadius.circular(12),
            image: _imageFilePath != null
                ? DecorationImage(
                    image: FileImage(File(_imageFilePath!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _imageFilePath == null
              ? const Center(
                  child: Text('Image Preview', style: TextStyle(color: Colors.white54)),
                )
              : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from Gallery'),
        )
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2A2D36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }
} 