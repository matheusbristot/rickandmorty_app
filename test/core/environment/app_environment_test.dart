import 'package:flutter_test/flutter_test.dart';
import 'package:rickandmorty_app/core/environment/app_environment.dart';
import 'package:rickandmorty_app/core/environment/fixture_network_client_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carrega o endpoint configurado para cada ambiente', () async {
    // Arrange
    // Act
    final dev = await AppEnvironmentConfig.load(AppEnvironment.dev);
    final stg = await AppEnvironmentConfig.load(AppEnvironment.stg);
    final prd = await AppEnvironmentConfig.load(AppEnvironment.prd);

    // Assert
    expect(dev.apiBaseUrl, 'fixture://dev/api/');
    expect(dev.fixtureRoot, 'assets/fixtures/dev');
    expect(stg.apiBaseUrl, 'fixture://stg/api/');
    expect(stg.fixtureRoot, 'assets/fixtures/stg');
    expect(prd.apiBaseUrl, 'https://rickandmortyapi.com/api/');
    expect(prd.fixtureRoot, isNull);
  });

  test('resolve o ambiente informado por dart-define', () {
    // Arrange
    const fallback = AppEnvironment.stg;

    // Act
    final dev = appEnvironmentFromDefine('dev', fallback: AppEnvironment.prd);
    final prod = appEnvironmentFromDefine('prod', fallback: AppEnvironment.dev);
    final unknown = appEnvironmentFromDefine('unknown', fallback: fallback);

    // Assert
    expect(dev, AppEnvironment.dev);
    expect(prod, AppEnvironment.prd);
    expect(unknown, AppEnvironment.stg);
  });

  test(
    'carrega episódio e personagens em lote a partir das fixtures',
    () async {
      // Arrange
      final client = FixtureNetworkClientImpl(
        fixtureRoot: 'assets/fixtures/dev',
      );

      // Act
      final episode = await client.getJson('episode/1') as Map;
      final characters = await client.getJsonUri(
        Uri.parse('https://rickandmortyapi.com/api/character/1,2,3'),
      ) as List;

      // Assert
      expect(episode['name'], 'Pilot (DEV)');
      expect(characters, hasLength(3));
      expect((characters[0] as Map)['name'], 'Rick Sanchez (DEV)');
    },
  );
}
