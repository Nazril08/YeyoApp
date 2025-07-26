import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/bookmark.dart';
import 'add_edit_bookmark_page.dart';

class BookmarkManagerPage extends StatefulWidget {
  const BookmarkManagerPage({super.key});

  @override
  State<BookmarkManagerPage> createState() => _BookmarkManagerPageState();
}

class _BookmarkManagerPageState extends State<BookmarkManagerPage> {
  late final Box<Bookmark> _bookmarkBox;
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _bookmarkBox = Hive.box('bookmarks');
    _updateCategories();
    _bookmarkBox.listenable().addListener(_updateCategories);
  }

  @override
  void dispose() {
    _bookmarkBox.listenable().removeListener(_updateCategories);
    super.dispose();
  }

  void _updateCategories() {
    if (mounted) {
      final allBookmarks = _bookmarkBox.values.toList();
      final uniqueCategories = allBookmarks.map((b) => b.category).toSet().toList();
      setState(() {
        _categories = ['All Categories', ...uniqueCategories];
        if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F222A),
      appBar: AppBar(
        title: Text(
          'Bookmark Vault',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F222A),
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBookmarkList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditBookmarkPage()),
          );
        },
        backgroundColor: const Color(0xFF6A6BF5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search bookmarks...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2A2D36),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2D36),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: const Text('Filter', style: TextStyle(color: Colors.white54)),
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, color: Colors.white54),
              dropdownColor: const Color(0xFF2A2D36),
              style: const TextStyle(color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue == 'All Categories' ? null : newValue;
                });
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkList() {
    return ValueListenableBuilder<Box<Bookmark>>(
      valueListenable: _bookmarkBox.listenable(),
      builder: (context, box, _) {
        var bookmarks = box.values.toList().cast<Bookmark>();

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          bookmarks = bookmarks
              .where((b) =>
                  b.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  b.url.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        // Apply category filter
        if (_selectedCategory != null) {
          bookmarks = bookmarks.where((b) => b.category == _selectedCategory).toList();
        }

        // Sort by creation date
        bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (bookmarks.isEmpty) {
          return const Center(
            child: Text(
              'Your vault is empty.\nTap + to add a bookmark.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return Slidable(
              key: ValueKey(bookmark.id),
              startActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) => _navigateToEditPage(bookmark),
                    backgroundColor: const Color(0xFF21B7CA),
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                    borderRadius: BorderRadius.circular(16),
                  ),
                ],
              ),
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                dismissible: DismissiblePane(onDismissed: () {
                   _deleteBookmark(bookmark, index);
                }),
                children: [
                  SlidableAction(
                    onPressed: (context) => _deleteBookmark(bookmark, index),
                    backgroundColor: const Color(0xFFFE4A49),
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                    borderRadius: BorderRadius.circular(16),
                  ),
                ],
              ),
              child: _buildBookmarkItem(bookmark),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
        );
      },
    );
  }

  Widget _buildBookmarkItem(Bookmark bookmark) {
    final domain = Uri.parse(bookmark.url).host;
    final time = timeago.format(bookmark.createdAt);
    final emojiCategory = _getEmojiForCategory(bookmark.category);

    return GestureDetector(
      onTap: () => _launchUrl(bookmark.url),
      // onLongPress: () => _showOptionsBottomSheet(bookmark), // Replaced by Slidable
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D36),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Favicon, Domain, and Category
            Row(
              children: [
                Image.network(
                  'https://www.google.com/s2/favicons?sz=32&domain_url=$domain',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.link, size: 20, color: Colors.white54),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    domain,
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$emojiCategory ${bookmark.category}',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Body: Title, URL, and optional Image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bookmark.title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bookmark.url,
                        style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.5), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (bookmark.imageUrl != null && bookmark.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: bookmark.imageUrl!.startsWith('http')
                          ? Image.network(
                              bookmark.imageUrl!,
                              width: 80,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 80, height: 60),
                            )
                          : Image.file(
                              File(bookmark.imageUrl!),
                              width: 80,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 80, height: 60),
                            ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Footer: Timestamp
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                time,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmojiForCategory(String category) {
    if (category.toLowerCase().contains('github')) return '🔖';
    if (category.toLowerCase().contains('gambar') || category.toLowerCase().contains('image')) return '📷';
    if (category.toLowerCase().contains('artikel') || category.toLowerCase().contains('article')) return '📄';
    if (category.toLowerCase().contains('inspirasi')) return '🧠';
    if (category.toLowerCase().contains('catatan') || category.toLowerCase().contains('note')) return '📌';
    return '🔗';
  }

  void _navigateToEditPage(Bookmark bookmark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditBookmarkPage(bookmark: bookmark),
      ),
    );
  }
  
  void _deleteBookmark(Bookmark bookmark, int index) {
    // We store the bookmark temporarily in case of undo
    final deletedBookmark = Bookmark(
      title: bookmark.title,
      url: bookmark.url,
      category: bookmark.category,
      imageUrl: bookmark.imageUrl,
      createdAt: bookmark.createdAt,
    );
    
    bookmark.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedBookmark.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // To preserve order, we'd ideally insert at the original index.
            // But Hive doesn't support insertion at index.
            // Re-adding it will place it at the end, but sorting will fix the view.
            _bookmarkBox.add(deletedBookmark);
          },
        ),
      ),
    );
  }


  void _showDeleteConfirmation(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2D36),
          title: Text('Delete Bookmark?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "${bookmark.title}"?',
              style: GoogleFonts.inter(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                bookmark.delete();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1F222A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }
} 