import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/validate_feature_dependencies.dart';

void main() {
  late Directory projectDirectory;

  setUp(() {
    projectDirectory = Directory.systemTemp.createTempSync('feature-di-test-');
  });

  tearDown(() {
    projectDirectory.deleteSync(recursive: true);
  });

  test('aceita feature com pubspec, composição e import no app', () {
    // Arrange
    final paths = _createProject(projectDirectory, featureName: 'payments');
    _write(paths.featurePubspec, '''name: payments_feature

dependencies:
  flutter:
    sdk: flutter
''');
    _write(paths.featureEntrypoint, 'library payments_feature;');
    _write(
      paths.featureDependencies,
      "import '../features/payments/domain.dart';",
    );
    _write(paths.appDependencies, "import 'payments_dependencies.dart';");
    _write(paths.rootPubspec, '''name: test_app

dependencies:
  payments_feature:
    path: lib/features/payments
''');

    // Act
    final issues = validateFeatureDependencies(
      featuresDirectory: paths.featuresDirectory,
      diDirectory: paths.diDirectory,
      appDependenciesFile: paths.appDependencies,
      rootPubspecFile: paths.rootPubspec,
    );

    // Assert
    expect(issues, isEmpty);
  });

  test('exige arquivo de composição quando existe pubspec na feature', () {
    // Arrange
    final paths = _createProject(projectDirectory, featureName: 'payments');
    _write(paths.featurePubspec, _featurePubspec());
    _write(paths.featureEntrypoint, 'library payments_feature;');
    _write(paths.rootPubspec, _rootPubspec());

    // Act
    final issues = validateFeatureDependencies(
      featuresDirectory: paths.featuresDirectory,
      diDirectory: paths.diDirectory,
      appDependenciesFile: paths.appDependencies,
      rootPubspecFile: paths.rootPubspec,
    );

    // Assert
    expect(issues, hasLength(1));
    expect(issues.single, contains('payments_dependencies.dart'));
  });

  test('exige import no app_dependencies quando o arquivo existe', () {
    // Arrange
    final paths = _createProject(projectDirectory, featureName: 'payments');
    _write(paths.featurePubspec, _featurePubspec());
    _write(paths.featureEntrypoint, 'library payments_feature;');
    _write(paths.featureDependencies, '// composição da feature');
    _write(paths.appDependencies, '// import ausente');
    _write(paths.rootPubspec, _rootPubspec());

    // Act
    final issues = validateFeatureDependencies(
      featuresDirectory: paths.featuresDirectory,
      diDirectory: paths.diDirectory,
      appDependenciesFile: paths.appDependencies,
      rootPubspecFile: paths.rootPubspec,
    );

    // Assert
    expect(issues, hasLength(1));
    expect(issues.single, contains('app_dependencies.dart'));
  });

  test('reporta arquitetura inválida quando falta pubspec e composição', () {
    // Arrange
    final paths = _createProject(projectDirectory, featureName: 'payments');
    paths.featureDirectory.createSync(recursive: true);

    // Act
    final issues = validateFeatureDependencies(
      featuresDirectory: paths.featuresDirectory,
      diDirectory: paths.diDirectory,
      appDependenciesFile: paths.appDependencies,
      rootPubspecFile: paths.rootPubspec,
    );

    // Assert
    expect(issues, hasLength(3));
    expect(issues.first, contains('não é um package'));
    expect(issues, anyElement(contains('payments_dependencies.dart')));
  });

  test('rejeita feature que importa o package da aplicação', () {
    // Arrange
    final paths = _createProject(projectDirectory, featureName: 'payments');
    _write(paths.featurePubspec, _featurePubspec());
    _write(paths.featureEntrypoint, 'library payments_feature;');
    _write(paths.featureSource, "import 'package:test_app/app.dart';");
    _write(paths.featureDependencies, '// composição da feature');
    _write(paths.appDependencies, "import 'payments_dependencies.dart';");
    _write(paths.rootPubspec, _rootPubspec());

    // Act
    final issues = validateFeatureDependencies(
      featuresDirectory: paths.featuresDirectory,
      diDirectory: paths.diDirectory,
      appDependenciesFile: paths.appDependencies,
      rootPubspecFile: paths.rootPubspec,
    );

    // Assert
    expect(issues, hasLength(1));
    expect(issues.single, contains('dependência cíclica'));
  });

  test('rejeita feature que depende do package da aplicação', () {
    // Arrange
    final paths = _createProject(projectDirectory, featureName: 'payments');
    _write(paths.featurePubspec, '''name: payments_feature

dependencies:
  flutter:
    sdk: flutter
  test_app:
    path: ../../..
''');
    _write(paths.featureEntrypoint, 'library payments_feature;');
    _write(paths.featureDependencies, '// composição da feature');
    _write(paths.appDependencies, "import 'payments_dependencies.dart';");
    _write(paths.rootPubspec, _rootPubspec());

    // Act
    final issues = validateFeatureDependencies(
      featuresDirectory: paths.featuresDirectory,
      diDirectory: paths.diDirectory,
      appDependenciesFile: paths.appDependencies,
      rootPubspecFile: paths.rootPubspec,
    );

    // Assert
    expect(issues, hasLength(1));
    expect(issues.single, contains('dependência cíclica'));
  });
}

_ProjectPaths _createProject(Directory root, {required String featureName}) {
  final featuresDirectory = Directory('${root.path}/lib/features')
    ..createSync(recursive: true);
  final diDirectory = Directory('${root.path}/lib/core/di')
    ..createSync(recursive: true);
  final featureDirectory = Directory('${featuresDirectory.path}/$featureName');
  final featurePubspec = File('${featureDirectory.path}/pubspec.yaml');
  final featureDependencies = File(
    '${diDirectory.path}/${featureName}_dependencies.dart',
  );
  final appDependencies = File('${diDirectory.path}/app_dependencies.dart');
  return _ProjectPaths(
    featuresDirectory: featuresDirectory,
    diDirectory: diDirectory,
    featureDirectory: featureDirectory,
    featurePubspec: featurePubspec,
    featureEntrypoint: File('${featureDirectory.path}/lib/$featureName.dart'),
    featureSource: File('${featureDirectory.path}/data/source.dart'),
    featureDependencies: featureDependencies,
    appDependencies: appDependencies,
    rootPubspec: File('${root.path}/pubspec.yaml'),
  );
}

String _featurePubspec() {
  return '''name: payments_feature

dependencies:
  flutter:
    sdk: flutter
''';
}

String _rootPubspec() {
  return '''name: test_app

dependencies:
  payments_feature:
    path: lib/features/payments
''';
}

void _write(File file, String content) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

final class _ProjectPaths {
  const _ProjectPaths({
    required this.featuresDirectory,
    required this.diDirectory,
    required this.featureDirectory,
    required this.featurePubspec,
    required this.featureEntrypoint,
    required this.featureSource,
    required this.featureDependencies,
    required this.appDependencies,
    required this.rootPubspec,
  });

  final Directory featuresDirectory;
  final Directory diDirectory;
  final Directory featureDirectory;
  final File featurePubspec;
  final File featureEntrypoint;
  final File featureSource;
  final File featureDependencies;
  final File appDependencies;
  final File rootPubspec;
}
