import 'package:flutter/material.dart';

import '../../features/character_catalog/presentation/pages/character_catalog_page.dart';
import '../../features/character_catalog/presentation/viewmodels/character_catalog_view_model.dart';
import '../../features/episode/presentation/pages/episode_page.dart';
import '../../features/episode/presentation/viewmodels/episode_view_model.dart';

final class HomePage extends StatefulWidget {
  const HomePage({required this.catalog, required this.episode, super.key});
  final CharacterCatalogViewModel catalog;
  final EpisodeViewModel episode;

  @override
  State<HomePage> createState() => _HomePageState();
}

final class _HomePageState extends State<HomePage> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _selected,
      children: [
        CharacterCatalogPage(viewModel: widget.catalog),
        EpisodePage(viewModel: widget.episode),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selected,
      onDestinationSelected: (value) => setState(() => _selected = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: 'Personagens',
        ),
        NavigationDestination(
          icon: Icon(Icons.movie_outlined),
          label: 'Episódios',
        ),
      ],
    ),
  );
}
