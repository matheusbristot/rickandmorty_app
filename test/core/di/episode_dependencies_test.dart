import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rickandmorty_app/core/di/episode_dependencies.dart';
import 'package:rickandmorty_app/core/environment/app_environment.dart';

import '../../support/test_mocks.dart';

void main() {
  test('produção usa o endpoint de episódios como escopo do cache', () {
    // Arrange
    const config = AppEnvironmentConfig(
      environment: AppEnvironment.prd,
      apiBaseUrl: 'https://rickandmortyapi.com/api/',
    );

    // Act
    final scope = episodeCacheScope(config);

    // Assert
    expect(scope, 'https://rickandmortyapi.com/api/episode');
  });

  for (final environment in [AppEnvironment.dev, AppEnvironment.stg]) {
    test('preserva a separação de fixtures em ${environment.name}', () {
      // Arrange
      final config = AppEnvironmentConfig(
        environment: environment,
        apiBaseUrl: 'fixture://${environment.name}/api/',
        fixtureRoot: 'assets/fixtures/${environment.name}',
      );

      // Act
      final scope = episodeCacheScope(config);

      // Assert
      expect(
        scope,
        'fixture://${environment.name}/api/episode|assets/fixtures/${environment.name}',
      );
    });
  }

  test('a composição entrega o escopo ao cache local do episódio', () async {
    // Arrange
    final cache = MockCache();
    final client = MockNetworkClient();
    when(() => cache.getString(any())).thenAnswer((_) async => null);
    const scope = 'fixture://dev/api/episode|assets/fixtures/dev';
    final repository = createEpisodeRepository(client, cache, scope);

    // Act
    await repository.getCachedEpisode(3);

    // Assert
    verify(
      () => cache.getString(
        '["fixture://dev/api/episode|assets/fixtures/dev",3]',
      ),
    ).called(1);
  });
}
