import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rickandmorty_app/core/di/character_catalog_dependencies.dart';
import 'package:rickandmorty_app/core/environment/app_environment.dart';
import 'package:character_catalog_feature/data/datasources/character_catalog_local_impl.dart';
import 'package:character_catalog_feature/domain/entities/character_filter.dart';

import '../../support/test_mocks.dart';

void main() {
  test('produção identifica o endpoint e a primeira página na chave', () async {
    // Arrange
    const config = AppEnvironmentConfig(
      environment: AppEnvironment.prd,
      apiBaseUrl: 'https://rickandmortyapi.com/api/',
    );
    final cache = MockCache();
    when(() => cache.getString(any())).thenAnswer((_) async => null);
    final source = CharacterCatalogLocalImpl(
      cache,
      scope: characterCatalogCacheScope(config),
    );

    // Act
    await source.read(const CharacterFilter());

    // Assert
    verify(
      () =>
          cache.getString('["https://rickandmortyapi.com/api/character",{},1]'),
    ).called(1);
    verifyNoMoreInteractions(cache);
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
      final scope = characterCatalogCacheScope(config);

      // Assert
      expect(
        scope,
        'fixture://${environment.name}/api/character|assets/fixtures/${environment.name}',
      );
    });
  }
}
