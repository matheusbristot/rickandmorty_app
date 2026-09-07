import 'package:flutter/material.dart';
import 'package:character_catalog_feature/character_catalog.dart';
import 'package:episode_feature/episode.dart';

import 'core/di/app_dependencies.dart';
import 'core/environment/app_environment.dart';
import 'core/navigation/home_page.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppEnvironmentConfig.load(environment);
  final dependencies = AppDependencies.create(config);
  runApp(
    MyApp(
      viewModel: dependencies.createEpisodeViewModel(),
      catalogViewModel: dependencies.catalogViewModel,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({required this.viewModel, this.catalogViewModel, super.key});

  final CharacterCatalogViewModel? catalogViewModel;

  final EpisodeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick & Morty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF157A6E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      ),
      home: catalogViewModel == null
          ? EpisodePage(viewModel: viewModel)
          : HomePage(catalog: catalogViewModel!, episode: viewModel),
    );
  }
}
