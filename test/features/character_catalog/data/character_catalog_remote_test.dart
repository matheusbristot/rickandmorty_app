import 'package:character/character_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:character_catalog_feature/data/datasources/character_catalog_remote_impl.dart';
import 'package:character_catalog_feature/domain/entities/character_filter.dart';
import 'package:character_catalog_feature/domain/entities/character_page.dart';

import '../../../support/test_mocks.dart';

void main() {
  setUpAll(registerTestFallbacks);

  test('envia todos os filtros e converte a página para o domínio', () async {
    // Arrange
    final client = MockPaginatedClient();
    final source = CharacterCatalogRemoteImpl(client);
    const filter = CharacterFilter(
      name: ' Rick & Morty ',
      status: CharacterStatus.alive,
      species: ' Human ',
      type: ' Clone ',
      gender: CharacterGender.male,
    );
    final next = Uri.parse('https://example.test/api/character?page=2');
    when(
      () => client.getPage<CharacterModel>(
        any(),
        decodeItem: any(named: 'decodeItem'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResponse(
        info: PaginationInfo(count: 4, pages: 2, next: next, prev: null),
        results: const [
          CharacterModel(
            id: 1,
            name: 'Rick',
            status: 'Alive',
            species: 'Human',
            imageUrl: '',
          ),
        ],
      ),
    );

    // Act
    final page = await source.fetch(filter);

    // Assert
    expect(page.characters.single.name, 'Rick');
    expect(page.count, 4);
    expect(page.next, next);
    final path =
        verify(
              () => client.getPage<CharacterModel>(
                captureAny(),
                decodeItem: any(named: 'decodeItem'),
              ),
            ).captured.single
            as String;
    expect(Uri.parse(path).queryParameters, {
      'name': 'Rick & Morty',
      'status': 'alive',
      'species': 'Human',
      'type': 'Clone',
      'gender': 'male',
    });
  });

  test('segue a URL recebida sem reconstruir os filtros', () async {
    // Arrange
    final client = MockPaginatedClient();
    final next = Uri.parse(
      'https://example.test/api/character?page=2&name=Rick',
    );
    when(
      () => client.getPageUri<CharacterModel>(
        next,
        decodeItem: any(named: 'decodeItem'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResponse(
        info: const PaginationInfo(count: 1, pages: 1, next: null, prev: null),
        results: [],
      ),
    );

    // Act
    final page = await CharacterCatalogRemoteImpl(client)
        .fetch(const CharacterFilter(), next: next);

    // Assert
    expect(page.next, isNull);
    verify(
      () => client.getPageUri<CharacterModel>(
        next,
        decodeItem: any(named: 'decodeItem'),
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });

  test('404 inicial representa busca sem resultados', () async {
    // Arrange
    final client = MockPaginatedClient();
    when(
      () => client.getPage<CharacterModel>(
        any(),
        decodeItem: any(named: 'decodeItem'),
      ),
    ).thenThrow(const NetworkException(message: 'Not found', statusCode: 404));

    // Act
    final page = await CharacterCatalogRemoteImpl(client)
        .fetch(const CharacterFilter(name: 'absent'));

    // Assert
    expect(page.characters, isEmpty);
    expect(page.count, 0);
    expect(page.next, isNull);
  });

  for (final scenario in [
    (
      error: const NetworkException(message: 'secret', statusCode: 429),
      kind: CatalogFailureKind.rateLimited,
    ),
    (
      error: const NetworkException(message: 'secret'),
      kind: CatalogFailureKind.network,
    ),
    (
      error: const FormatException('secret'),
      kind: CatalogFailureKind.invalidData,
    ),
  ]) {
    test('traduz erro para ${scenario.kind}', () async {
      // Arrange
      final client = MockPaginatedClient();
      when(
        () => client.getPage<CharacterModel>(
          any(),
          decodeItem: any(named: 'decodeItem'),
        ),
      ).thenThrow(scenario.error);

      // Act
      final future = CharacterCatalogRemoteImpl(client)
          .fetch(const CharacterFilter());

      // Assert
      await expectLater(
        future,
        throwsA(
          isA<CatalogFailure>().having(
            (error) => error.kind,
            'kind',
            scenario.kind,
          ),
        ),
      );
    });
  }

  test('404 em página seguinte permanece um erro recuperável', () async {
    // Arrange
    final client = MockPaginatedClient();
    final next = Uri.parse('https://example.test/api/character?page=2');
    when(
      () => client.getPageUri<CharacterModel>(
        next,
        decodeItem: any(named: 'decodeItem'),
      ),
    ).thenThrow(const NetworkException(message: 'missing', statusCode: 404));

    // Act
    final future = CharacterCatalogRemoteImpl(client)
        .fetch(const CharacterFilter(), next: next);

    // Assert
    await expectLater(future, throwsA(isA<CatalogFailure>()));
  });
}
