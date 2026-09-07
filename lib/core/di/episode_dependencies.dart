import 'package:cache/cache.dart';
import 'package:character/character_data.dart';
import 'package:episode_feature/episode.dart';
import 'package:network/network.dart';

EpisodeViewModel createEpisodeViewModel(EpisodeRepository repository) {
  return EpisodeViewModelImpl(
    LoadEpisodeUseCaseImpl(repository),
    RetryCharacterUseCaseImpl(repository),
    EpisodeInputParserImpl(),
    EpisodeMessageMapperImpl(),
  );
}

EpisodeRepository createEpisodeRepository(
  NetworkClient networkClient,
  Cache cache,
) {
  final CharacterRemoteDataSource characterDataSource =
      CharacterRemoteDataSourceImpl(networkClient);
  final CharacterRepository characterRepository = CharacterRepositoryImpl(
    characterDataSource,
  );
  final EpisodeLocalDataSource localDataSource = EpisodeLocalDataSourceImpl(
    cache,
  );
  final EpisodeRemoteDataSource remoteDataSource = EpisodeRemoteDataSourceImpl(
    networkClient,
  );

  return EpisodeRepositoryImpl(
    localDataSource,
    remoteDataSource,
    characterRepository,
  );
}
