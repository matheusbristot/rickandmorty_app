import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rickandmorty_app/features/episode/data/datasources/local/episode_local_data_source_impl.dart';

import '../../../../support/test_mocks.dart';

void main() {
  test('carrega e converte o episódio armazenado no cache', () async {
    // Arrange
    final cache = MockCache();
    when(() => cache.getString('episode_3')).thenAnswer(
      (_) async =>
          '{"id":3,"name":"Anatomy Park","air_date":"December 16, 2013",'
          '"episode":"S01E03","character_urls":[]}',
    );
    final dataSource = EpisodeLocalDataSourceImpl(cache);

    // Act
    final episode = await dataSource.getEpisode(3);

    // Assert
    expect(episode?.id, 3);
    expect(episode?.name, 'Anatomy Park');
    verify(() => cache.getString('episode_3')).called(1);
  });

  test('ignora JSON inválido armazenado no cache', () async {
    // Arrange
    final cache = MockCache();
    when(() => cache.getString('episode_3'))
        .thenAnswer((_) async => '{invalid');
    final dataSource = EpisodeLocalDataSourceImpl(cache);

    // Act
    final episode = await dataSource.getEpisode(3);

    // Assert
    expect(episode, isNull);
  });
}
