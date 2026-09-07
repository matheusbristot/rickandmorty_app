import 'package:flutter_test/flutter_test.dart';
import 'package:character_catalog_feature/domain/entities/character_page.dart';
import 'package:character_catalog_feature/presentation/state/character_catalog_state.dart';

import '../../../support/test_fixtures.dart';

void main() {
  test('agrega por ID sem duplicar e mantém a ordem recebida', () {
    // Arrange
    final state = CharacterCatalogState(
      characters: [
        TestFixtures.character(1, 'Rick'),
        TestFixtures.character(2, 'Morty'),
      ],
    );
    final snapshot = CharacterPageSnapshot(
      page: TestFixtures.catalogPage(id: 1, name: 'Updated'),
    );

    // Act
    final result = state.accept(snapshot);

    // Assert
    expect(result.characters.map((item) => item.id), [1, 2]);
    expect(result.characters.first.name, 'Updated');
    expect(() => result.characters.clear(), throwsUnsupportedError);
  });

  test('erro preserva dados sem expor detalhes técnicos', () {
    // Arrange
    final state = CharacterCatalogState(
      characters: [TestFixtures.character(1, 'Rick')],
      fromCache: true,
    );

    // Act
    final result = state.finish(Exception('SocketException secret'));

    // Assert
    expect(result.characters.single.name, 'Rick');
    expect(result.fromCache, isTrue);
    expect(result.error, isNot(contains('secret')));
    expect(result.loading, isFalse);
  });
}
