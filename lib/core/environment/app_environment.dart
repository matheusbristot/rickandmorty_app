enum AppEnvironment { dev, stg, prd }

const _defaultDevApiBaseUrl = String.fromEnvironment(
  'DEV_API_BASE_URL',
  defaultValue: 'fixture://dev/api/',
);
const _defaultDevFixtureRoot = String.fromEnvironment(
  'DEV_FIXTURE_ROOT',
  defaultValue: 'assets/fixtures/dev',
);
const _defaultStgApiBaseUrl = String.fromEnvironment(
  'STG_API_BASE_URL',
  defaultValue: 'fixture://stg/api/',
);
const _defaultStgFixtureRoot = String.fromEnvironment(
  'STG_FIXTURE_ROOT',
  defaultValue: 'assets/fixtures/stg',
);
const _defaultPrdApiBaseUrl = String.fromEnvironment('PRD_API_BASE_URL');

AppEnvironment appEnvironmentFromDefine(
  String value, {
  required AppEnvironment fallback,
}) {
  return switch (value) {
    'dev' => AppEnvironment.dev,
    'stg' => AppEnvironment.stg,
    'prd' || 'prod' => AppEnvironment.prd,
    _ => fallback,
  };
}

final class AppEnvironmentConfig {
  const AppEnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.fixtureRoot,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String? fixtureRoot;

  bool get usesFixtures => fixtureRoot != null;

  static Future<AppEnvironmentConfig> load(AppEnvironment environment) {
    final apiBaseUrl = switch (environment) {
      AppEnvironment.dev => _defaultDevApiBaseUrl,
      AppEnvironment.stg => _defaultStgApiBaseUrl,
      AppEnvironment.prd => _defaultPrdApiBaseUrl,
    };
    final fixtureRoot = switch (environment) {
      AppEnvironment.dev => _defaultDevFixtureRoot,
      AppEnvironment.stg => _defaultStgFixtureRoot,
      AppEnvironment.prd => null,
    };
    if (apiBaseUrl.isEmpty) {
      return Future.error(
        StateError('API_BASE_URL não configurada para o ambiente.'),
      );
    }

    return Future.value(
      AppEnvironmentConfig(
        environment: environment,
        apiBaseUrl: apiBaseUrl,
        fixtureRoot: fixtureRoot,
      ),
    );
  }
}
