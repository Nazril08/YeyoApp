import 'package:flutter/material.dart';

// A simple data model for our searchable features
class SearchableFeature {
  final String title;
  final String description;
  final Widget page;

  SearchableFeature({
    required this.title,
    required this.description,
    required this.page,
  });
}

class SearchPage extends StatefulWidget {
  final List<SearchableFeature> allFeatures;

  const SearchPage({super.key, required this.allFeatures});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchableFeature> _filteredFeatures = [];

  @override
  void initState() {
    super.initState();
    _filteredFeatures = widget.allFeatures;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFeatures = widget.allFeatures.where((feature) {
        final titleMatch = feature.title.toLowerCase().contains(query);
        final descriptionMatch = feature.description.toLowerCase().contains(query);
        return titleMatch || descriptionMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search features...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: _filteredFeatures.isEmpty
          ? const Center(child: Text('No features found.'))
          : ListView.builder(
              itemCount: _filteredFeatures.length,
              itemBuilder: (context, index) {
                final feature = _filteredFeatures[index];
                return ListTile(
                  title: Text(feature.title),
                  subtitle: Text(feature.description),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => feature.page),
                    );
                  },
                );
              },
            ),
    );
  }
} 