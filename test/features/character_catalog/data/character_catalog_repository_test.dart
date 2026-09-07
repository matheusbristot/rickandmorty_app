import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_catalog_feature/data/repositories/character_catalog_repository_impl.dart';
import 'package:character_catalog_feature/domain/entities/character_filter.dart';
import 'package:character_catalog_feature/domain/entities/character_page.dart';

import '../../../support/test_fixtures.dart';
import '../../../support/test_mocks.dart';

void main() {
  setUpAll(registerTestFallbacks);
  const filter = CharacterFilter();
  late MockCatalogLocal local;
  late MockCatalogRemote remote;
  late CharacterCatalogRepositoryImpl repository;
  setUp(() {
    local = MockCatalogLocal();
    remote = MockCatalogRemote();
    repository = CharacterCatalogRepositoryImpl(local, remote);
    when(() => local.save(any(), any(), next: any(named: 'next')))
        .thenAnswer((_) async {});
  });

  test('emite cache antes da rede e salva atualização', () async {
    // Arrange
    final cached = TestFixtures.catalogPage(name: 'Cached');
    final fresh = TestFixtures.catalogPage(name: 'Fresh');
    when(() => local.read(filter)).thenAnswer((_) async => cached);
    when(() => remote.fetch(filter)).thenAnswer((_) async => fresh);

    // Act
    final results = await repository.load(filter).toList();

    // Assert
    expect(results.map((result) => result.fromCache), [true, false]);
    expect(results.first.page, same(cached));
    expect(results.last.page, same(fresh));
    verify(() => local.save(filter, fresh)).called(1);
  });

  test('entrega cache e depois sinaliza falha offline', () async {
    // Arrange
    final cached = TestFixtures.catalogPage();
    const failure = CatalogFailure(CatalogFailureKind.network);
    when(() => local.read(filter)).thenAnswer((_) async => cached);
    when(() => remote.fetch(filter)).thenThrow(failure);

    // Act
    final stream = repository.load(filter);

    // Assert
    await expectLater(
      stream,
      emitsInOrder([
        isA<CharacterPageSnapshot>().having(
          (value) => value.fromCache,
          'cache',
          true,
        ),
        emitsError(same(failure)),
        emitsDone,
      ]),
    );
    verifyNever(() => local.save(any(), any()));
  });

  test('falhas de cache não impedem resultado remoto', () async {
    // Arrange
    final fresh = TestFixtures.catalogPage();
    when(() => local.read(filter)).thenThrow(Exception('disk'));
    when(() => remote.fetch(filter)).thenAnswer((_) async => fresh);
    when(() => local.save(filter, fresh)).thenThrow(Exception('disk'));

    // Act
    final results = await repository.load(filter).toList();

    // Assert
    expect(results.single.page, same(fresh));
    expect(results.single.fromCache, isFalse);
  });
}
