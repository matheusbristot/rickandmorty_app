import 'package:cache/cache.dart';
import 'package:network/network.dart';

import '../environment/app_environment.dart';

import '../../features/character_catalog/data/datasources/character_catalog_local_impl.dart';
import '../../features/character_catalog/data/datasources/character_catalog_remote_impl.dart';
import '../../features/character_catalog/data/repositories/character_catalog_repository_impl.dart';
import '../../features/character_catalog/domain/usecases/load_character_catalog.dart';
import '../../features/character_catalog/presentation/viewmodels/character_catalog_view_model.dart';

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
