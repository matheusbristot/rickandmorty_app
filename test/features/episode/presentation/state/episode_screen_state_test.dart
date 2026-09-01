import 'package:character/character.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode_load_event.dart';
import 'package:rickandmorty_app/features/episode/presentation/state/episode_screen_state.dart';

import '../../../../support/test_fixtures.dart';

void main() {
  test(
    'atualiza personagens por URL mesmo quando eventos chegam fora de ordem',
    () {
      // Arrange
      final rickUrl = Uri.parse('https://rickandmortyapi.com/api/character/1');
      final mortyUrl = Uri.parse('https://rickandmortyapi.com/api/character/2');
      final episode = Episode(
        id: 1,
        name: 'Pilot',
        airDate: 'December 2, 2013',
        code: 'S01E01',
        characterUrls: [rickUrl, mortyUrl],
        characters: const [],
      );
      var state = const EpisodeScreenState();

      // Act
      state = state.reduce(EpisodeStarted(episode), 'Falha parcial.');
      state = state.reduce(
        EpisodeCharacterUpdated(
          CharacterLoadEvent.loaded(
            url: mortyUrl,
            character: TestFixtures.character(2, 'Morty Smith'),
          ),
        ),
        'Falha parcial.',
      );
      state = state.reduce(
        EpisodeCharacterUpdated(
          CharacterLoadEvent.loaded(
            url: rickUrl,
            character: TestFixtures.character(1, 'Rick Sanchez'),
          ),
        ),
        'Falha parcial.',
      );

      // Assert
      expect(state.characters.map((item) => item.character?.name), [
        'Morty Smith',
        'Rick Sanchez',
      ]);
      expect(
        state.characters.every(
          (item) => item.status == CharacterLoadStatus.loaded,
        ),
        isTrue,
      );
      expect(state.episode?.characters, hasLength(2));
    },
  );

  test('mantém o item de personagem para retry quando há erro', () {
    // Arrange
    final url = Uri.parse('https://rickandmortyapi.com/api/character/1');
    final episode = Episode(
      id: 1,
      name: 'Pilot',
      airDate: 'December 2, 2013',
      code: 'S01E01',
      characterUrls: [url],
      characters: const [],
    );
    var state = const EpisodeScreenState();

    // Act
    state = state.reduce(EpisodeStarted(episode), 'Falha parcial.');
    state = state.reduce(
      EpisodeCharacterUpdated(
        CharacterLoadEvent.error(url: url, message: 'offline'),
      ),
      'Falha parcial.',
    );

    // Assert
    expect(state.canRetry(url), isTrue);
    expect(state.characters.single.status, CharacterLoadStatus.error);
    expect(state.errorMessage, 'Falha parcial.');
  });
}
