import 'package:flutter/services.dart';

enum AppEnvironment { dev, stg, prd }

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

extension AppEnvironmentFile on AppEnvironment {
  String get envFile => switch (this) {
    AppEnvironment.dev => '.env.dev',
    AppEnvironment.stg => '.env.stg',
    AppEnvironment.prd => '.env.prd',
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

  static Future<AppEnvironmentConfig> load(
    AppEnvironment environment, {
    AssetBundle? bundle,
  }) async {
    final content = await (bundle ?? rootBundle).loadString(
      environment.envFile,
    );
    final values = _parse(content);
    final apiBaseUrl = values['API_BASE_URL'];
    if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL não configurada.');
    }

    return AppEnvironmentConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      fixtureRoot: values['FIXTURE_ROOT'],
    );
  }

  static Map<String, String> _parse(String content) {
    final values = <String, String>{};
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final separator = trimmed.indexOf('=');
      if (separator <= 0) continue;
      final key = trimmed.substring(0, separator).trim();
      final value = trimmed.substring(separator + 1).trim();
      values[key] = _unquote(value);
    }
    return values;
  }

  static String _unquote(String value) {
    if (value.length < 2) return value;
    final isQuoted =
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"));
    return isQuoted ? value.substring(1, value.length - 1) : value;
  }
}
