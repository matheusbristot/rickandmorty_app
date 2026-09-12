import 'package:cache/cache.dart';
import 'package:character/character_data.dart';
import 'package:episode_feature/episode.dart';
import 'package:network/network.dart';

import '../environment/app_environment.dart';

String episodeCacheScope(AppEnvironmentConfig config) {
  final endpoint = Uri.parse(config.apiBaseUrl).resolve('episode').toString();
  final fixtureRoot = config.fixtureRoot;
  return fixtureRoot == null ? endpoint : '$endpoint|$fixtureRoot';
}

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
  String scope,
) {
  final CharacterRemoteDataSource characterDataSource =
      CharacterRemoteDataSourceImpl(networkClient);
  final CharacterRepository characterRepository = CharacterRepositoryImpl(
    characterDataSource,
  );
  final EpisodeLocalDataSource localDataSource = EpisodeLocalDataSourceImpl(
    cache,
    scope: scope,
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
