import 'package:character/character_data.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:test/test.dart';

import '../../../support/test_fixtures.dart';
import '../../../support/test_mocks.dart';

void main() {
  setUpAll(registerCharacterTestFallbacks);

  test('requisita o endpoint de personagens em lote', () async {
    // Arrange
    final urls = [
      CharacterTestFixtures.characterUrl(1),
      CharacterTestFixtures.characterUrl(2),
    ];
    final client = MockNetworkClient();
    when(() => client.getJsonUri(any())).thenAnswer((invocation) async {
      final uri = invocation.positionalArguments.single as Uri;
      final ids = uri.pathSegments.last.split(',');
      return [
        for (final id in ids)
          CharacterTestFixtures.characterJson(int.parse(id), _nameFor(id)),
      ];
    });
    final dataSource = CharacterRemoteDataSourceImpl(client);
    final repository = CharacterRepositoryImpl(dataSource);

    // Act
    final events = await repository.getCharactersByUrls(urls).toList();
    final characters = events
        .where((event) => event.status == CharacterLoadStatus.loaded)
        .map((event) => event.character!)
        .toList();

    // Assert
    final requestedUri =
        verify(() => client.getJsonUri(captureAny())).captured.single as Uri;
    expect(requestedUri.pathSegments.last, '1,2');
    expect(characters.map((character) => character.name), [
      'Rick Sanchez',
      'Morty Smith',
    ]);
  });

  test(
    'carrega todas as 30 URLs de personagens em uma resposta em lote',
    () async {
      // Arrange
      final urls = List.generate(
        30,
        (index) => CharacterTestFixtures.characterUrl(index + 1),
      );
      final client = MockNetworkClient();
      when(() => client.getJsonUri(any())).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments.single as Uri;
        return [
          for (final id in uri.pathSegments.last.split(','))
            CharacterTestFixtures.characterJson(int.parse(id), 'Character $id'),
        ];
      });
      final repository = CharacterRepositoryImpl(
        CharacterRemoteDataSourceImpl(client),
      );

      // Act
      final events = await repository.getCharactersByUrls(urls).toList();

      // Assert
      expect(
        events.where((event) => event.status == CharacterLoadStatus.loaded),
        hasLength(30),
      );
      final requestedUri =
          verify(() => client.getJsonUri(captureAny())).captured.single as Uri;
      expect(requestedUri.pathSegments.last.split(','), hasLength(30));
    },
  );

  test('emite erro de um personagem e continua os demais', () async {
    // Arrange
    final failedUrl = CharacterTestFixtures.characterUrl(3);
    final urls = [
      CharacterTestFixtures.characterUrl(1),
      CharacterTestFixtures.characterUrl(2),
      failedUrl,
    ];
    final client = MockNetworkClient();
    when(() => client.getJsonUri(any())).thenAnswer((invocation) async {
      final uri = invocation.positionalArguments.single as Uri;
      if (uri.pathSegments.last.contains(',')) {
        throw const NetworkException(message: 'offline');
      }
      if (uri == failedUrl) {
        throw const NetworkException(message: 'offline');
      }
      final id = int.parse(uri.pathSegments.last);
      return CharacterTestFixtures.characterJson(id, _nameFor('$id'));
    });
    final repository = CharacterRepositoryImpl(
      CharacterRemoteDataSourceImpl(client),
    );

    // Act
    final events = await repository.getCharactersByUrls(urls).toList();

    // Assert
    expect(
      events.where((event) => event.status == CharacterLoadStatus.loaded),
      hasLength(2),
    );
    expect(
      events.where(
        (event) =>
            event.url == failedUrl && event.status == CharacterLoadStatus.error,
      ),
      hasLength(1),
    );
    verify(() => client.getJsonUri(failedUrl)).called(1);
  });
}

String _nameFor(String id) => id == '1' ? 'Rick Sanchez' : 'Morty Smith';
