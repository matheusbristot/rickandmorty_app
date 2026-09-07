import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rickandmorty_app/features/character_catalog/domain/entities/character_page.dart';
import 'package:rickandmorty_app/features/character_catalog/domain/entities/character_filter.dart';
import 'package:rickandmorty_app/features/character_catalog/presentation/pages/character_catalog_page.dart';
import 'package:rickandmorty_app/features/character_catalog/presentation/viewmodels/character_catalog_view_model.dart';

import '../../../support/test_fixtures.dart';
import '../../../support/test_mocks.dart';

void main() {
  setUpAll(registerTestFallbacks);

  testWidgets('carrega automaticamente, mostra cards e carrega mais', (
    tester,
  ) async {
    // Arrange
    final load = MockLoadCharacterCatalog();
    final next = Uri.parse('https://example.test/?page=2');
    when(() => load.execute(any())).thenAnswer(
      (_) => Stream.value(
        CharacterPageSnapshot(page: TestFixtures.catalogPage(next: next)),
      ),
    );
    when(() => load.execute(any(), next: next)).thenAnswer(
      (_) => Stream.value(
        CharacterPageSnapshot(
          page: TestFixtures.catalogPage(id: 2, name: 'Morty', count: 2),
        ),
      ),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterCatalogPage(
          viewModel: CharacterCatalogViewModelImpl(load),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Rick Sanchez'), findsOneWidget);
    expect(find.text('Morty'), findsOneWidget);
    expect(find.text('2 de 2 personagens'), findsOneWidget);
    expect(find.text('Fim da lista.'), findsOneWidget);
    expect(find.text('Carregar mais'), findsNothing);
  });

  testWidgets('aplica nome e limpa os filtros', (tester) async {
    // Arrange
    final load = MockLoadCharacterCatalog();
    when(() => load.execute(any())).thenAnswer(
      (_) => Stream.value(
        CharacterPageSnapshot(page: CharacterPage(characters: [], count: 0)),
      ),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterCatalogPage(
          viewModel: CharacterCatalogViewModelImpl(load),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Morty');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    // Assert
    final filters = verify(() => load.execute(captureAny())).captured
        .cast<CharacterFilter>();
    expect(filters.map((filter) => filter.name), ['', 'Morty', '']);
    expect(find.textContaining('Nenhum personagem encontrado'), findsOneWidget);
  });

  testWidgets('mostra erro e permite nova tentativa', (tester) async {
    // Arrange
    final load = MockLoadCharacterCatalog();
    when(() => load.execute(any())).thenAnswer(
      (_) => Stream.error(const CatalogFailure(CatalogFailureKind.network)),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterCatalogPage(
          viewModel: CharacterCatalogViewModelImpl(load),
        ),
      ),
    );
    await tester.pumpAndSettle();
    when(() => load.execute(any())).thenAnswer(
      (_) =>
          Stream.value(CharacterPageSnapshot(page: TestFixtures.catalogPage())),
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Rick Sanchez'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
    verify(() => load.execute(any())).called(2);
  });
}
