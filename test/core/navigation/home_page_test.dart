import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/test_mocks.dart';

import 'package:rickandmorty_app/app.dart';
import 'package:rickandmorty_app/core/di/app_dependencies.dart';
import 'package:rickandmorty_app/core/environment/app_environment.dart';

void main() {
  testWidgets('navega entre catálogo e episódio preservando a consulta', (
    tester,
  ) async {
    // Arrange
    final config = await AppEnvironmentConfig.load(AppEnvironment.dev);
    final cache = MockCache();
    when(() => cache.getString(any())).thenAnswer((_) async => null);
    when(() => cache.setString(any(), any())).thenAnswer((_) async {});
    final dependencies = AppDependencies.create(config, cache: cache);

    // Act
    await tester.pumpWidget(
      MyApp(
        viewModel: dependencies.createEpisodeViewModel(),
        catalogViewModel: dependencies.catalogViewModel,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Rick');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Episódios'));
    await tester.pumpAndSettle();
    final episodeVisible = find
        .text('Explore um episódio')
        .evaluate()
        .isNotEmpty;
    await tester.tap(find.text('Personagens').last);
    await tester.pumpAndSettle();

    // Assert
    expect(episodeVisible, isTrue);
    expect(find.text('Rick Sanchez (DEV)'), findsOneWidget);
    expect(find.text('1 de 1 personagens'), findsOneWidget);
    expect(find.text('Morty Smith (DEV)'), findsNothing);
  });
}
