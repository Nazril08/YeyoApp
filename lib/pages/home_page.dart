import 'package:flutter/material.dart';
import 'package:yeyo/pages/novel_tracker_page.dart';
import 'package:yeyo/pages/todo_list_page.dart';
import 'package:yeyo/widgets/feature_card.dart';

class Feature {
  final String title;
  final IconData icon;
  final Widget page;

  Feature({required this.title, required this.icon, required this.page});
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Feature> features = [
      Feature(
        title: 'Novel Tracker',
        icon: Icons.book,
        page: const NovelTrackerPage(),
      ),
      Feature(
        title: 'To-Do List',
        icon: Icons.check_box,
        page: const TodoListPage(),
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 150.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Halo!'),
              centerTitle: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final feature = features[index];
                  return FeatureCard(
                    title: feature.title,
                    icon: feature.icon,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => feature.page),
                      );
                    },
                  );
                },
                childCount: features.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
