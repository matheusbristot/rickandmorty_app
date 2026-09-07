import 'package:cache/cache.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:character/character_data.dart';
import 'package:character_catalog_feature/domain/entities/character_filter.dart';
import 'package:character_catalog_feature/domain/entities/character_page.dart';
import 'package:character_catalog_feature/domain/repositories/character_catalog_repository.dart';
import 'package:character_catalog_feature/domain/usecases/load_character_catalog.dart';
import 'package:character_catalog_feature/data/datasources/character_catalog_remote.dart';
import 'package:character_catalog_feature/data/datasources/character_catalog_local.dart';
import 'package:episode_feature/data/datasources/episode_local_data_source.dart';
import 'package:episode_feature/data/datasources/episode_remote_data_source.dart';
import 'package:episode_feature/domain/repositories/episode_repository.dart';

import 'test_fixtures.dart';

class MockCache extends Mock implements Cache {}

final class MockPaginatedClient extends Mock implements PaginatedClient {}

final class MockCatalogRemote extends Mock implements CharacterCatalogRemote {}

final class MockCatalogLocal extends Mock implements CharacterCatalogLocal {}

final class MockCatalogRepository extends Mock
    implements CharacterCatalogRepository {}

final class MockLoadCharacterCatalog extends Mock
    implements LoadCharacterCatalog {}

class MockCharacterRepository extends Mock implements CharacterRepository {}

class MockEpisodeLocalDataSource extends Mock
    implements EpisodeLocalDataSource {}

class MockEpisodeRemoteDataSource extends Mock
    implements EpisodeRemoteDataSource {}

class MockEpisodeRepository extends Mock implements EpisodeRepository {}

void registerTestFallbacks() {
  registerFallbackValue(const CharacterFilter());
  registerFallbackValue(CharacterPage(characters: [], count: 0));
  registerFallbackValue(Uri.parse('https://example.test/api/character?page=2'));
  registerFallbackValue(CharacterModel.fromJson);
  registerFallbackValue(<Uri>[]);
  registerFallbackValue(<String, String>{});
  registerFallbackValue(TestFixtures.episodeModel());
}
