import 'package:cache/cache.dart';
import 'package:character_catalog_feature/character_catalog.dart';
import 'package:episode_feature/episode.dart';
import 'package:network/network.dart';

import 'character_catalog_dependencies.dart' as catalog;
import '../environment/app_environment.dart';
import '../environment/fixture_network_client_impl.dart';
import 'episode_dependencies.dart' as episode;

class AppDependencies {
  AppDependencies._({
    required this.episodeRepository,
    required this.catalogViewModel,
  });

  final CharacterCatalogViewModel catalogViewModel;

  final EpisodeRepository episodeRepository;

  EpisodeViewModel createEpisodeViewModel() {
    return episode.createEpisodeViewModel(episodeRepository);
  }

  static AppDependencies create(AppEnvironmentConfig config, {Cache? cache}) {
    final NetworkClient networkClient = config.usesFixtures
        ? FixtureNetworkClientImpl(fixtureRoot: config.fixtureRoot!)
        : NetworkClientImpl(config: NetworkConfig(baseUrl: config.apiBaseUrl));
    final Cache storage = cache ?? SharedPreferencesCacheImpl();
    return AppDependencies._(
      catalogViewModel: catalog.createCharacterCatalogViewModel(
        networkClient,
        storage,
        catalog.characterCatalogCacheScope(config),
      ),
      episodeRepository: episode.createEpisodeRepository(
        networkClient,
        storage,
        episode.episodeCacheScope(config),
      ),
    );
  }
}
