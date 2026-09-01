import 'package:flutter/material.dart';

import 'core/di/app_dependencies.dart';
import 'core/environment/app_environment.dart';
import 'features/episode/presentation/pages/episode_page.dart';
import 'features/episode/presentation/viewmodels/episode_view_model.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppEnvironmentConfig.load(environment);
  final dependencies = AppDependencies.create(config);
  runApp(MyApp(viewModel: dependencies.createEpisodeViewModel()));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.viewModel, super.key});

  final EpisodeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick & Morty Episodes',
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
      home: EpisodePage(viewModel: viewModel),
    );
  }
}
