import 'package:character/character.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode_load_event.dart';
import 'package:rickandmorty_app/features/episode/domain/usecases/load_episode_use_case.dart';
import 'package:rickandmorty_app/features/episode/domain/usecases/retry_character_use_case.dart';
import 'package:rickandmorty_app/features/episode/presentation/input/episode_input_parser.dart';
import 'package:rickandmorty_app/features/episode/presentation/messages/episode_message_mapper.dart';
import 'package:rickandmorty_app/features/episode/presentation/viewmodels/episode_view_model.dart';

import '../../../../support/test_fixtures.dart';
import '../../../../support/test_mocks.dart';

void main() {
  setUpAll(registerTestFallbacks);

  test(
    'remove erros antigos quando a tentativa seguinte tem sucesso',
    () async {
      // Arrange
      final repository = MockEpisodeRepository();
      var calls = 0;
      when(() => repository.getCachedEpisode(1)).thenAnswer((_) async => null);
      when(() => repository.fetchEpisode(1)).thenAnswer((_) {
        calls++;
        final url = TestFixtures.characterUrl(1);
        final episode = TestFixtures.episode(
          'Pilot',
          characterUrls: [url],
          characters: calls == 1
              ? const []
              : [TestFixtures.character(1, 'Rick Sanchez')],
        );
        return Stream.fromIterable([
          EpisodeStarted(episode.copyWithCharacters(const [])),
          if (calls == 1)
            EpisodeCharacterUpdated(
              CharacterLoadEvent.error(
                url: url,
                message: 'Muitas requisições.',
              ),
            )
          else
            EpisodeCharacterUpdated(
              CharacterLoadEvent.loaded(
                url: url,
                character: TestFixtures.character(1, 'Rick Sanchez'),
              ),
            ),
          EpisodeCompleted(episode: episode, hasErrors: calls == 1),
        ]);
      });
      final viewModel = _viewModel(repository);
      addTearDown(viewModel.dispose);

      // Act
      await viewModel.search();
      final firstStatus = viewModel.characters.single.status;
      await viewModel.search();

      // Assert
      expect(firstStatus, CharacterLoadStatus.error);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.characters, hasLength(1));
      expect(viewModel.characters.single.status, CharacterLoadStatus.loaded);
      expect(viewModel.characters.single.character?.name, 'Rick Sanchez');
      verify(() => repository.fetchEpisode(1)).called(2);
    },
  );

  test('tenta novamente apenas o personagem selecionado', () async {
    // Arrange
    final url = TestFixtures.characterUrl(1);
    final repository = MockEpisodeRepository();
    when(() => repository.getCachedEpisode(1)).thenAnswer((_) async => null);
    when(() => repository.fetchEpisode(1)).thenAnswer(
      (_) => Stream.fromIterable([
        EpisodeStarted(TestFixtures.episode('Pilot', characterUrls: [url])),
        EpisodeCharacterUpdated(
          CharacterLoadEvent.error(url: url, message: 'offline'),
        ),
        EpisodeCompleted(
          episode: TestFixtures.episode('Pilot', characterUrls: [url]),
          hasErrors: true,
        ),
      ]),
    );
    when(() => repository.fetchCharacter(url))
        .thenAnswer((_) async => TestFixtures.character(1, 'Rick Sanchez'));
    final viewModel = _viewModel(repository);
    addTearDown(viewModel.dispose);

    // Act
    await viewModel.search();
    await viewModel.retryCharacter(url);

    // Assert
    expect(viewModel.characters.single.status, CharacterLoadStatus.loaded);
    expect(viewModel.characters.single.character?.name, 'Rick Sanchez');
    verify(() => repository.fetchEpisode(1)).called(1);
    verify(() => repository.fetchCharacter(url)).called(1);
  });
}

EpisodeViewModel _viewModel(MockEpisodeRepository repository) {
  return EpisodeViewModelImpl(
    LoadEpisodeUseCaseImpl(repository),
    RetryCharacterUseCaseImpl(repository),
    EpisodeInputParserImpl(),
    EpisodeMessageMapperImpl(),
  );
}
