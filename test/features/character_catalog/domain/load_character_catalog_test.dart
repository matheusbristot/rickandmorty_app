import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_catalog_feature/domain/entities/character_filter.dart';
import 'package:character_catalog_feature/domain/entities/character_page.dart';
import 'package:character_catalog_feature/domain/usecases/load_character_catalog.dart';

import '../../../support/test_fixtures.dart';
import '../../../support/test_mocks.dart';

void main() {
  test('caso de uso encaminha filtro e próxima página ao contrato', () async {
    // Arrange
    const filter = CharacterFilter(name: 'Rick');
    final next = Uri.parse('https://example.test/?page=2');
    final repository = MockCatalogRepository();
    final snapshot = CharacterPageSnapshot(page: TestFixtures.catalogPage());
    when(() => repository.load(filter, next: next))
        .thenAnswer((_) => Stream.value(snapshot));

    // Act
    final result = await LoadCharacterCatalogImpl(repository)
        .execute(filter, next: next)
        .toList();

    // Assert
    expect(result, [snapshot]);
    verify(() => repository.load(filter, next: next)).called(1);
  });
}
