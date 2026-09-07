import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rickandmorty_app/features/character_catalog/data/datasources/character_catalog_local_impl.dart';
import 'package:rickandmorty_app/features/character_catalog/domain/entities/character_filter.dart';

import '../../../support/test_fixtures.dart';
import '../../../support/test_mocks.dart';

void main() {
  test('chave usa endpoint, filtros e página sem repetir a URL', () async {
    // Arrange
    final cache = MockCache();
    when(() => cache.getString(any())).thenAnswer((_) async => null);
    when(() => cache.setString(any(), any())).thenAnswer((_) async {});
    const endpoint = 'https://rickandmortyapi.com/api/character';
    final source = CharacterCatalogLocalImpl(cache, scope: endpoint);
    const filter = CharacterFilter(status: CharacterStatus.alive);
    final requested = Uri.parse('$endpoint?page=3&status=alive');
    final following = Uri.parse('$endpoint?page=4&status=alive');
    final page = TestFixtures.catalogPage(next: following);

    // Act
    await source.save(filter, page, next: requested);
    await source.read(
      filter,
      next: Uri.parse('$endpoint/?status=alive&page=3'),
    );

    // Assert
    const key =
        '["https://rickandmortyapi.com/api/character",{"status":"alive"},3]';
    final saved =
        verify(() => cache.setString(key, captureAny())).captured.single
            as String;
    expect(jsonDecode(saved)['next'], following.toString());
    verify(() => cache.getString(key)).called(1);
  });

  test('primeira página explícita e implícita usam a mesma chave', () async {
    // Arrange
    final cache = MockCache();
    when(() => cache.getString(any())).thenAnswer((_) async => null);
    const endpoint = 'https://rickandmortyapi.com/api/character';
    final source = CharacterCatalogLocalImpl(cache, scope: endpoint);
    const filter = CharacterFilter();

    // Act
    await source.read(filter);
    await source.read(filter, next: Uri.parse('$endpoint?page=1'));
    await source.read(filter, next: Uri.parse('$endpoint?page=0'));

    // Assert
    verify(
      () =>
          cache.getString('["https://rickandmortyapi.com/api/character",{},1]'),
    ).called(3);
  });

  test('página inválida não colide com a primeira página', () async {
    // Arrange
    final cache = MockCache();
    final source = CharacterCatalogLocalImpl(
      cache,
      scope: 'https://example.test/character',
    );

    // Act
    final future = source.read(
      const CharacterFilter(),
      next: Uri.parse('https://example.test/character?page=invalid'),
    );

    // Assert
    await expectLater(future, throwsFormatException);
    verifyZeroInteractions(cache);
  });

  test(
    'cache distingue filtros, página e ambiente, normalizando espaços',
    () async {
      // Arrange
      final cache = MockCache();
      when(() => cache.getString(any())).thenAnswer((_) async => null);
      final source = CharacterCatalogLocalImpl(cache, scope: 'dev');
      final other = CharacterCatalogLocalImpl(cache, scope: 'prd');

      // Act
      await source.read(const CharacterFilter(name: ' Rick '));
      await source.read(const CharacterFilter(name: 'Rick'));
      await source.read(const CharacterFilter(name: 'Morty'));
      await source.read(
        const CharacterFilter(name: 'Rick'),
        next: Uri.parse('https://example.test/?page=2'),
      );
      await other.read(const CharacterFilter(name: 'Rick'));

      // Assert
      final keys = verify(() => cache.getString(captureAny())).captured;
      expect(keys[0], keys[1]);
      expect(keys.skip(1).toSet(), hasLength(4));
    },
  );

  test('persiste e restaura personagens e próxima página', () async {
    // Arrange
    final cache = MockCache();
    when(() => cache.setString(any(), any())).thenAnswer((_) async {});
    final source = CharacterCatalogLocalImpl(cache, scope: 'prd');
    final page = TestFixtures.catalogPage(
      next: Uri.parse('https://example.test/?page=2'),
    );
    const filter = CharacterFilter();

    // Act
    await source.save(filter, page);
    final saved = verify(() => cache.setString(captureAny(), captureAny()))
        .captured;
    when(() => cache.getString(saved[0] as String))
        .thenAnswer((_) async => saved[1] as String);
    final restored = await source.read(filter);

    // Assert
    expect(restored!.characters.single.name, 'Rick Sanchez');
    expect(restored.count, page.count);
    expect(restored.next, page.next);
    expect(jsonDecode(saved[1] as String)['characters'], hasLength(1));
  });

  for (final value in [
    'not json',
    '{}',
    '[]',
    '{"count":-1,"next":null,"characters":[]}',
  ]) {
    test('ignora cache inválido: $value', () async {
      // Arrange
      final cache = MockCache();
      when(() => cache.getString(any())).thenAnswer((_) async => value);

      // Act
      final result = await CharacterCatalogLocalImpl(
        cache,
        scope: 'dev',
      ).read(const CharacterFilter());

      // Assert
      expect(result, isNull);
    });
  }
}
