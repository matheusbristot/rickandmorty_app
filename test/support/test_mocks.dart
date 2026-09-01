import 'package:cache/cache.dart';
import 'package:character/character.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rickandmorty_app/features/episode/data/datasources/episode_local_data_source.dart';
import 'package:rickandmorty_app/features/episode/data/datasources/episode_remote_data_source.dart';
import 'package:rickandmorty_app/features/episode/domain/repositories/episode_repository.dart';

import 'test_fixtures.dart';

class MockCache extends Mock implements Cache {}

class MockCharacterRepository extends Mock implements CharacterRepository {}

class MockEpisodeLocalDataSource extends Mock
    implements EpisodeLocalDataSource {}

class MockEpisodeRemoteDataSource extends Mock
    implements EpisodeRemoteDataSource {}

class MockEpisodeRepository extends Mock implements EpisodeRepository {}

void registerTestFallbacks() {
  registerFallbackValue(<Uri>[]);
  registerFallbackValue(<String, String>{});
  registerFallbackValue(TestFixtures.episodeModel());
}
