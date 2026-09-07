import 'package:cache/cache.dart';
import 'package:character_catalog_feature/character_catalog.dart';
import 'package:network/network.dart';

import '../environment/app_environment.dart';

String characterCatalogCacheScope(AppEnvironmentConfig config) {
  final endpoint = Uri.parse(config.apiBaseUrl).resolve('character').toString();
  final fixtureRoot = config.fixtureRoot;
  return fixtureRoot == null ? endpoint : '$endpoint|$fixtureRoot';
}

CharacterCatalogViewModel createCharacterCatalogViewModel(
  NetworkClient client,
  Cache cache,
  String scope,
) {
  final repository = CharacterCatalogRepositoryImpl(
    CharacterCatalogLocalImpl(cache, scope: scope),
    CharacterCatalogRemoteImpl(PaginatedClientImpl(client)),
  );
  return CharacterCatalogViewModelImpl(LoadCharacterCatalogImpl(repository));
}
