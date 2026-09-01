import 'package:character/character.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:rickandmorty_app/features/episode/data/models/episode_model.dart';
import 'package:rickandmorty_app/features/episode/data/repositories/episode_repository_impl.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode_failure.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode_load_event.dart';

import '../../../../support/test_fixtures.dart';
import '../../../../support/test_mocks.dart';

void main() {
  setUpAll(registerTestFallbacks);

  test('salva o episódio concluído no cache', () async {
    // Arrange
    final firstUrl = TestFixtures.characterUrl(1);
    final secondUrl = TestFixtures.characterUrl(2);
    final localDataSource = MockEpisodeLocalDataSource();
    final remoteDataSource = MockEpisodeRemoteDataSource();
    final characterRepository = MockCharacterRepository();
    when(() => remoteDataSource.getEpisode(3)).thenAnswer(
      (_) async =>
          TestFixtures.episodeModel(characterUrls: [firstUrl, secondUrl]),
    );
    when(() => characterRepository.getCharactersByUrls(any())).thenAnswer(
      (_) => _characterEvents({
        firstUrl: TestFixtures.character(1, 'Rick Sanchez'),
        secondUrl: TestFixtures.character(2, 'Morty Smith'),
      }),
    );
    when(() => localDataSource.saveEpisode(any())).thenAnswer((_) async {});
    final repository = EpisodeRepositoryImpl(
      localDataSource,
      remoteDataSource,
      characterRepository,
    );

    // Act
    final events = await repository.fetchEpisode(3).toList();

    // Assert
    final savedEpisode =
        verify(() => localDataSource.saveEpisode(captureAny())).captured.single
            as EpisodeModel;
    expect(events.last, isA<EpisodeCompleted>());
    expect(savedEpisode.id, 3);
    expect(savedEpisode.characters, hasLength(2));
  });

  test('salva o episódio mesmo com personagem indisponível', () async {
    // Arrange
    final availableUrl = TestFixtures.characterUrl(1);
    final failedUrl = TestFixtures.characterUrl(2);
    final localDataSource = MockEpisodeLocalDataSource();
    final remoteDataSource = MockEpisodeRemoteDataSource();
    final characterRepository = MockCharacterRepository();
    when(() => remoteDataSource.getEpisode(3)).thenAnswer(
      (_) async =>
          TestFixtures.episodeModel(characterUrls: [availableUrl, failedUrl]),
    );
    when(() => characterRepository.getCharactersByUrls(any())).thenAnswer(
      (_) => _characterEvents(
        {availableUrl: TestFixtures.character(1, 'Rick Sanchez')},
        failedUrls: {failedUrl},
      ),
    );
    when(() => localDataSource.saveEpisode(any())).thenAnswer((_) async {});
    final repository = EpisodeRepositoryImpl(
      localDataSource,
      remoteDataSource,
      characterRepository,
    );

    // Act
    final events = await repository.fetchEpisode(3).toList();
    final completed = events.last as EpisodeCompleted;

    // Assert
    final savedEpisode =
        verify(() => localDataSource.saveEpisode(captureAny())).captured.single
            as EpisodeModel;
    expect(completed.hasErrors, isTrue);
    expect(savedEpisode.characters, hasLength(1));
    expect(savedEpisode.characterUrls, [availableUrl, failedUrl]);
  });

  test('traduz status HTTP para falhas de domínio', () async {
    // Arrange
    final expectedKinds = {
      404: EpisodeFailureKind.notFound,
      429: EpisodeFailureKind.tooManyRequests,
      500: EpisodeFailureKind.network,
    };
    final repositories = {
      for (final statusCode in expectedKinds.keys)
        statusCode: _repositoryWithStatus(statusCode),
    };

    // Act
    final actualKinds = <int, EpisodeFailureKind>{};
    for (final entry in expectedKinds.entries) {
      try {
        await repositories[entry.key]!.fetchEpisode(3).toList();
      } on EpisodeFailure catch (failure) {
        actualKinds[entry.key] = failure.kind;
      }
    }

    // Assert
    expect(actualKinds, expectedKinds);
  });
}

EpisodeRepositoryImpl _repositoryWithStatus(int statusCode) {
  final remoteDataSource = MockEpisodeRemoteDataSource();
  when(() => remoteDataSource.getEpisode(3)).thenThrow(
    NetworkException(message: 'transport failure', statusCode: statusCode),
  );
  return EpisodeRepositoryImpl(
    MockEpisodeLocalDataSource(),
    remoteDataSource,
    MockCharacterRepository(),
  );
}

Stream<CharacterLoadEvent> _characterEvents(
  Map<Uri, Character> characters, {
  Set<Uri> failedUrls = const {},
}) async* {
  for (final url in characters.keys.followedBy(failedUrls)) {
    yield CharacterLoadEvent.loading(url: url);
    if (failedUrls.contains(url)) {
      yield CharacterLoadEvent.error(
        url: url,
        message: 'Personagem indisponível.',
      );
      continue;
    }
    yield CharacterLoadEvent.loaded(url: url, character: characters[url]!);
  }
}
