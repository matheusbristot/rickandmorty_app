import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:episode_feature/data/datasources/local/episode_local_data_source_impl.dart';

import '../../../../support/test_mocks.dart';
import '../../../../support/test_fixtures.dart';

void main() {
  test('carrega e converte o episódio armazenado no cache', () async {
    // Arrange
    final cache = MockCache();
    const key = '["https://rickandmortyapi.com/api/episode",3]';
    when(() => cache.getString(key)).thenAnswer(
      (_) async =>
          '{"id":3,"name":"Anatomy Park","air_date":"December 16, 2013",'
          '"episode":"S01E03","character_urls":[]}',
    );
    final dataSource = EpisodeLocalDataSourceImpl(
      cache,
      scope: 'https://rickandmortyapi.com/api/episode',
    );

    // Act
    final episode = await dataSource.getEpisode(3);

    // Assert
    expect(episode?.id, 3);
    expect(episode?.name, 'Anatomy Park');
    verify(() => cache.getString(key)).called(1);
  });

  test('ignora JSON inválido armazenado no cache', () async {
    // Arrange
    final cache = MockCache();
    const key = '["https://rickandmortyapi.com/api/episode",3]';
    when(() => cache.getString(key)).thenAnswer((_) async => '{invalid');
    final dataSource = EpisodeLocalDataSourceImpl(
      cache,
      scope: 'https://rickandmortyapi.com/api/episode',
    );

    // Act
    final episode = await dataSource.getEpisode(3);

    // Assert
    expect(episode, isNull);
  });

  test('salva usando endpoint e identificador do episódio', () async {
    // Arrange
    final cache = MockCache();
    when(() => cache.setString(any(), any())).thenAnswer((_) async {});
    final dataSource = EpisodeLocalDataSourceImpl(
      cache,
      scope: 'https://rickandmortyapi.com/api/episode',
    );
    final episode = TestFixtures.episodeModel(id: 3);

    // Act
    await dataSource.saveEpisode(episode);

    // Assert
    final captured = verify(() => cache.setString(captureAny(), captureAny()))
        .captured;
    expect(captured[0], '["https://rickandmortyapi.com/api/episode",3]');
  });

  test('separa episódios iguais por escopo de cache', () async {
    // Arrange
    final cache = MockCache();
    when(() => cache.getString(any())).thenAnswer((_) async => null);
    final production = EpisodeLocalDataSourceImpl(
      cache,
      scope: 'https://rickandmortyapi.com/api/episode',
    );
    final development = EpisodeLocalDataSourceImpl(
      cache,
      scope: 'fixture://dev/api/episode|assets/fixtures/dev',
    );

    // Act
    await production.getEpisode(3);
    await development.getEpisode(3);
    await production.getEpisode(4);

    // Assert
    final keys = verify(() => cache.getString(captureAny())).captured;
    expect(keys, [
      '["https://rickandmortyapi.com/api/episode",3]',
      '["fixture://dev/api/episode|assets/fixtures/dev",3]',
      '["https://rickandmortyapi.com/api/episode",4]',
    ]);
  });
}
