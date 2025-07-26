import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yeyo/models/novel.dart';
import 'package:yeyo/pages/novel_detail_page.dart';
import 'package:yeyo/pages/novel_settings_page.dart';

class NovelTrackerPage extends StatefulWidget {
  const NovelTrackerPage({super.key});

  @override
  State<NovelTrackerPage> createState() => _NovelTrackerPageState();
}

class _NovelTrackerPageState extends State<NovelTrackerPage> {
  late final Box<Novel> _novelBox;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _novelBox = Hive.box('novels');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novel Tracker', style: Theme.of(context).textTheme.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NovelSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _novelBox.listenable(),
        builder: (context, Box<Novel> box, _) {
          final allNovels = box.values.toList().cast<Novel>();
          final uniqueStatuses = allNovels.map((n) => n.status).toSet().toList();
          final statuses = ['All', 'Favorites', ...uniqueStatuses];

          final List<Novel> filteredNovels;
          if (_selectedStatus == 'Favorites') {
            filteredNovels = allNovels.where((novel) => novel.isFavorite).toList();
          } else if (_selectedStatus == 'All') {
            filteredNovels = allNovels;
          } else {
            filteredNovels = allNovels.where((novel) => novel.status == _selectedStatus).toList();
          }

          return Column(
            children: [
              _buildFilterChips(statuses),
              Expanded(
                child: filteredNovels.isEmpty
                    ? const Center(child: Text("No novels found for this filter."))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filteredNovels.length,
                        itemBuilder: (context, index) {
                          final novel = filteredNovels[index];
                          final novelKey = box.keyAt(allNovels.indexOf(novel));
                          return _buildNovelCard(context, novel, novelKey);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NovelDetailPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(List<String> statuses) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          bool isSelected = _selectedStatus == status;
          return ChoiceChip(
            label: Text(status),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedStatus = status;
                });
              }
            },
            backgroundColor: Theme.of(context).cardTheme.color?.withOpacity(0.5),
            selectedColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }

  Widget _buildNovelCard(BuildContext context, Novel novel, dynamic key) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NovelDetailPage(novel: novel, novelKey: key),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        elevation: 0,
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCardImage(novel.imageUrl),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  final updatedNovel = Novel()
                    ..title = novel.title
                    ..imageUrl = novel.imageUrl
                    ..status = novel.status
                    ..baseUrls = novel.baseUrls
                    ..lastChapterUrls = novel.lastChapterUrls
                    ..notes = novel.notes
                    ..isFavorite = !novel.isFavorite
                    ..synopsis = novel.synopsis
                    ..genres = novel.genres;
                  _novelBox.put(key, updatedNovel);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    novel.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: novel.isFavorite ? Colors.redAccent : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    novel.title.length > 25 ? '${novel.title.substring(0, 25)}...' : novel.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4.0, color: Colors.black87)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      novel.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(String imageUrl) {
    // This function remains the same
    if (imageUrl.isEmpty) {
      return Container(color: Theme.of(context).cardTheme.color);
    }
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Theme.of(context).cardTheme.color),
        errorWidget: (context, url, error) => Container(color: Theme.of(context).cardTheme.color, child: const Icon(Icons.error)),
      );
    } else {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).cardTheme.color, child: const Icon(Icons.broken_image)),
      );
    }
  }
}
