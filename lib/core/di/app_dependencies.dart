import 'package:cache/cache.dart';
import 'package:character/character_data.dart';
import 'package:network/network.dart';
import 'package:rickandmorty_app/features/episode/data/datasources/episode_local_data_source.dart';
import 'package:rickandmorty_app/features/episode/data/datasources/local/episode_local_data_source_impl.dart';
import 'package:rickandmorty_app/features/episode/data/datasources/episode_remote_data_source.dart';
import 'package:rickandmorty_app/features/episode/data/datasources/remote/episode_remote_data_source_impl.dart';
import 'package:rickandmorty_app/features/episode/domain/usecases/load_episode_use_case.dart';
import 'package:rickandmorty_app/features/episode/domain/usecases/retry_character_use_case.dart';
import 'package:rickandmorty_app/features/episode/presentation/input/episode_input_parser.dart';
import 'package:rickandmorty_app/features/episode/presentation/messages/episode_message_mapper.dart';
import 'package:rickandmorty_app/features/episode/presentation/viewmodels/episode_view_model.dart';

import '../../features/episode/data/repositories/episode_repository_impl.dart';
import '../../features/episode/domain/repositories/episode_repository.dart';
import '../environment/app_environment.dart';
import '../environment/fixture_network_client_impl.dart';

class AppDependencies {
  AppDependencies._({required this.episodeRepository});

  final EpisodeRepository episodeRepository;

  EpisodeViewModel createEpisodeViewModel() {
    return EpisodeViewModelImpl(
      LoadEpisodeUseCaseImpl(episodeRepository),
      RetryCharacterUseCaseImpl(episodeRepository),
      EpisodeInputParserImpl(),
      EpisodeMessageMapperImpl(),
    );
  }

  static AppDependencies create(AppEnvironmentConfig config) {
    final NetworkClient networkClient = config.usesFixtures
        ? FixtureNetworkClientImpl(fixtureRoot: config.fixtureRoot!)
        : NetworkClientImpl(config: NetworkConfig(baseUrl: config.apiBaseUrl));
    final CharacterRemoteDataSource characterDataSource =
        CharacterRemoteDataSourceImpl(networkClient);
    final CharacterRepository characterRepository = CharacterRepositoryImpl(
      characterDataSource,
    );
    final Cache cache = SharedPreferencesCacheImpl();
    final EpisodeLocalDataSource localDataSource = EpisodeLocalDataSourceImpl(
      cache,
    );
    final EpisodeRemoteDataSource remoteDataSource =
        EpisodeRemoteDataSourceImpl(networkClient);

    return AppDependencies._(
      episodeRepository: EpisodeRepositoryImpl(
        localDataSource,
        remoteDataSource,
        characterRepository,
      ),
    );
  }
}
