import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode_load_event.dart';
import 'package:rickandmorty_app/features/episode/domain/usecases/load_episode_use_case.dart';

import '../../../../support/test_fixtures.dart';
import '../../../../support/test_mocks.dart';

void main() {
  test('emite o cache antes de iniciar a atualização remota', () async {
    // Arrange
    final cached = TestFixtures.episode('cached');
    final remote = TestFixtures.episode('remote');
    final repository = MockEpisodeRepository();
    when(() => repository.getCachedEpisode(1)).thenAnswer((_) async => cached);
    when(() => repository.fetchEpisode(1)).thenAnswer(
      (_) => Stream.fromIterable([
        EpisodeStarted(remote),
        EpisodeCompleted(episode: remote, hasErrors: false),
      ]),
    );
    final useCase = LoadEpisodeUseCaseImpl(repository);

    // Act
    final events = await useCase.execute(1).toList();

    // Assert
    expect(events, [
      isA<EpisodeCached>(),
      isA<EpisodeStarted>(),
      isA<EpisodeCompleted>(),
    ]);
    expect((events[0] as EpisodeCached).episode.name, 'cached');
    expect((events[1] as EpisodeStarted).episode.name, 'remote');
    verify(() => repository.getCachedEpisode(1)).called(1);
    verify(() => repository.fetchEpisode(1)).called(1);
  });
}
