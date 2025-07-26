import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yeyo/models/novel.dart';
import 'package:yeyo/services/scraping_service.dart';
import 'package:yeyo/widgets/novel_notes.dart';
import 'package:url_launcher/url_launcher.dart';

class NovelDetailPage extends StatefulWidget {
  final Novel? novel;
  final dynamic novelKey;

  const NovelDetailPage({super.key, this.novel, this.novelKey});

  @override
  State<NovelDetailPage> createState() => _NovelDetailPageState();
}

class _NovelDetailPageState extends State<NovelDetailPage> {
  late final Box<Novel> _novelBox;
  final _scrapingService = ScrapingService();

  late final TextEditingController _titleController;
  late final List<TextEditingController> _baseUrlControllers;
  late final List<TextEditingController> _lastChapterUrlControllers;
  late final TextEditingController _scrapeUrlController;
  late final TextEditingController _synopsisController;
  late final TextEditingController _genreController;
  late final TextEditingController _notesController;
  late String _status;
  String? _imagePath;
  String? _scrapedImageUrl;
  late bool _isEditing;
  bool _isScraping = false;
  bool _isEditingGenres = false;

  int _selectedTabIndex = 0;
  bool _isSynopsisExpanded = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.novel != null;
    _novelBox = Hive.box('novels');

    _titleController =
        TextEditingController(text: _isEditing ? widget.novel!.title : '');
    _status = _isEditing && widget.novel!.status.isNotEmpty
        ? widget.novel!.status
        : 'Belom Baca';
    
    _baseUrlControllers = _isEditing && widget.novel!.baseUrls.isNotEmpty
        ? widget.novel!.baseUrls.map((url) => TextEditingController(text: url)).toList()
        : [TextEditingController()];
        
    _lastChapterUrlControllers = _isEditing && widget.novel!.lastChapterUrls.isNotEmpty
        ? widget.novel!.lastChapterUrls.map((url) => TextEditingController(text: url)).toList()
        : [TextEditingController()];

    _scrapeUrlController = TextEditingController();
    _synopsisController =
        TextEditingController(text: _isEditing ? widget.novel!.synopsis ?? '' : '');
    _genreController =
        TextEditingController(text: _isEditing ? widget.novel!.genres ?? '' : '');
    _notesController =
        TextEditingController(text: _isEditing ? widget.novel!.notes : '');

    if (_isEditing) {
      if (widget.novel!.imageUrl.isNotEmpty) {
        if (widget.novel!.imageUrl.startsWith('http')) {
          _scrapedImageUrl = widget.novel!.imageUrl;
        } else {
          _imagePath = widget.novel!.imageUrl;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _baseUrlControllers.forEach((c) => c.dispose());
    _lastChapterUrlControllers.forEach((c) => c.dispose());
    _scrapeUrlController.dispose();
    _synopsisController.dispose();
    _genreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
        _scrapedImageUrl = null; 
      });
    }
  }

  void _saveChanges() {
    String finalImageUrl;
    if (_imagePath != null) {
      finalImageUrl = _imagePath!;
    } else if (_scrapedImageUrl != null) {
      finalImageUrl = _scrapedImageUrl!;
    } else if (_isEditing) {
      finalImageUrl = widget.novel!.imageUrl;
    } else {
      finalImageUrl = '';
    }

    final updatedNovel = Novel()
      ..title = _titleController.text
      ..status = _status
      ..notes = _notesController.text
      ..baseUrls = _baseUrlControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList()
      ..lastChapterUrls = _lastChapterUrlControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList()
      ..isFavorite = _isEditing ? widget.novel!.isFavorite : false
      ..imageUrl = finalImageUrl
      ..synopsis = _synopsisController.text
      ..genres = _genreController.text;

    if (_isEditing) {
      _novelBox.put(widget.novelKey, updatedNovel);
    } else {
      _novelBox.add(updatedNovel);
    }

    Navigator.pop(context);
  }

  void _deleteNovel() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Novel'),
          content: const Text(
              'Are you sure you want to delete this novel? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _novelBox.delete(widget.novelKey);
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back from the detail page
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleScrape() async {
    if (_scrapeUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a URL first.')),
      );
      return;
    }

    setState(() {
      _isScraping = true;
    });

    try {
      final data = await _scrapingService.scrapeNovelData(_scrapeUrlController.text);
      if (data.isNotEmpty && (data['title']?.isNotEmpty ?? false)) {
        setState(() {
          _titleController.text = data['title'] ?? '';
          _synopsisController.text = data['synopsis'] ?? '';
          _genreController.text = data['genres'] ?? '';
          if (_baseUrlControllers.isEmpty) {
            _baseUrlControllers.add(TextEditingController(text: _scrapeUrlController.text));
          } else {
            _baseUrlControllers[0].text = _scrapeUrlController.text;
          }
          _scrapedImageUrl = data['imageUrl'];
          _imagePath = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data fetched successfully!'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to get data. Check the URL or site structure.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isScraping = false;
      });
    }
  }

  void _launchUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open URL: $e')),
      );
    }
  }

  void _openLastChapter() async {
    final urls = _lastChapterUrlControllers
        .map((c) => c.text)
        .where((text) => text.trim().isNotEmpty)
        .toList();

    if (urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No chapter URL available.')),
      );
      return;
    }
      _launchUrl(urls.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteNovel,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            _buildHeaderImage(),
            const SizedBox(height: 24),
            _buildContentTabs(),
            const SizedBox(height: 24),
            _buildSelectedTabContent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveChanges,
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: _buildImageWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      return Image.file(
        File(_imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 60),
      );
    }
    if (_scrapedImageUrl != null && _scrapedImageUrl!.isNotEmpty) {
      return Image.network(
        _scrapedImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.error, size: 60),
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 60),
        SizedBox(height: 8),
        Text('Tap to add image')
      ],
    );
  }
  
  Widget _buildContentTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabItem(0, 'Details'),
          _buildTabItem(1, 'Tracking'),
          _buildTabItem(2, 'Links'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).cardTheme.color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    // This method returns the content based on the selected tab
    switch (_selectedTabIndex) {
      case 0:
        return _buildDetailsTab();
      case 1:
        return _buildTrackingTab();
      case 2:
        return _buildLinksTab();
      default:
        return Container();
    }
  }

  // Define _buildDetailsTab, _buildTrackingTab, and _buildLinksTab here
  // These will contain the form fields and widgets previously in _buildContentSheet
  
  // Example for _buildDetailsTab
  Widget _buildDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_titleController, 'Novel Title'),
        const SizedBox(height: 16),
        _buildTextField(_genreController, 'Genre(s)', hint: 'Action, Adventure, ...'),
        const SizedBox(height: 16),
        _buildSynopsisField(),
        const SizedBox(height: 16),
        _buildTextField(_notesController, 'Notes', maxLines: 4),
      ],
    );
  }
  
  Widget _buildTrackingTab() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        _buildStatusDropdown(),
        // ... other tracking widgets
      ],
    );
  }

  Widget _buildLinksTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Autofill from URL', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTextField(_scrapeUrlController, '', hint: 'Paste novel URL from wtr-lab.com...')),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isScraping ? null : _handleScrape,
              icon: _isScraping
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_for_offline),
              label: Text(_isScraping ? 'Fetching...' : 'Get Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildDynamicUrlFields(_baseUrlControllers, 'Base URL(s)'),
        const SizedBox(height: 16),
        _buildDynamicUrlFields(_lastChapterUrlControllers, 'Last Chapter URL(s)'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openLastChapter,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Last Chapter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).cardTheme.color,
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, {String? hint, int maxLines = 1}) {
    final textField = TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );

    if (label.isEmpty) {
      return textField;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        textField,
      ],
    );
  }
  
  Widget _buildSynopsisField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Synopsis', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _synopsisController,
          maxLines: _isSynopsisExpanded ? null : 3,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(_isSynopsisExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          isExpanded: true,
          dropdownColor: Theme.of(context).cardTheme.color,
          items: ['Belom Baca', 'Lagi Baca', 'Tamat']
              .map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ))
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _status = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDynamicUrlFields(List<TextEditingController> controllers, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
        ...controllers.map((controller) => Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _buildTextField(controller, ''),
        )).toList(),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            setState(() {
              controllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add URL'),
        ),
      ],
    );
  }
} 