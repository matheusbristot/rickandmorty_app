import 'dart:io';

List<String> validateFeatureDependencies({
  required Directory featuresDirectory,
  required Directory diDirectory,
  required File appDependenciesFile,
  required File rootPubspecFile,
}) {
  final issues = <String>[];
  if (!featuresDirectory.existsSync()) {
    return ['Diretório de features não encontrado: ${featuresDirectory.path}'];
  }
  if (!diDirectory.existsSync()) {
    return ['Diretório de composição não encontrado: ${diDirectory.path}'];
  }

  final appDependencies = appDependenciesFile.existsSync()
      ? appDependenciesFile.readAsLinesSync()
      : const <String>[];
  final rootPubspec = rootPubspecFile.existsSync()
      ? rootPubspecFile.readAsLinesSync()
      : const <String>[];
  final applicationPackageName = _packageName(rootPubspecFile);
  for (final featureDirectory in _featureDirectories(featuresDirectory)) {
    final featureName = _directoryName(featureDirectory);
    final pubspec = _file(featureDirectory, 'pubspec.yaml');
    final pubspecLines = pubspec.existsSync()
        ? pubspec.readAsLinesSync()
        : const <String>[];
    final packageName = _packageName(pubspec);
    if (!pubspec.existsSync()) {
      issues.add(
        'A feature "$featureName" não é um package: falta '
        '${pubspec.path}.',
      );
    } else if (packageName == null) {
      issues.add('${pubspec.path} deve declarar um nome de package válido.');
    } else {
      if (!_hasFlutterDependency(pubspecLines)) {
        issues.add(
          '${pubspec.path} deve declarar a dependência do SDK Flutter.',
        );
      }
      if (!_hasPathDependency(
        rootPubspec,
        packageName,
        featureDirectory,
        rootPubspecFile.parent,
      )) {
        issues.add(
          '${rootPubspecFile.path} deve registrar o package "$packageName" '
          'como dependência de caminho.',
        );
      }
      if (applicationPackageName != null &&
          _declaresDependency(pubspecLines, applicationPackageName)) {
        issues.add(
          'A feature "$featureName" não pode depender do package da '
          'aplicação; isso cria dependência cíclica com core.',
        );
      }
    }

    final entrypoint = _file(
      Directory('${featureDirectory.path}${Platform.pathSeparator}lib'),
      '$featureName.dart',
    );
    if (!entrypoint.existsSync()) {
      issues.add(
        'A feature "$featureName" precisa de uma biblioteca pública em '
        '${entrypoint.path}.',
      );
    }

    final dependencyFileName = '${featureName}_dependencies.dart';
    final dependencyFile = _file(diDirectory, dependencyFileName);
    if (!dependencyFile.existsSync()) {
      issues.add(
        'A feature "$featureName" não possui seu arquivo de composição: '
        '${dependencyFile.path}.',
      );
      continue;
    }
    if (!_importsFile(appDependencies, dependencyFileName)) {
      issues.add(
        '${appDependenciesFile.path} deve importar '
        '$dependencyFileName para compor a feature "$featureName".',
      );
    }
    if (applicationPackageName != null &&
        _importsApplicationPackage(
          featureDirectory,
          'package:$applicationPackageName/',
        )) {
      issues.add(
        'A feature "$featureName" não pode importar o package da aplicação; '
        'isso cria dependência cíclica com core.',
      );
    }
  }
  return issues;
}

Iterable<Directory> _featureDirectories(Directory featuresDirectory) {
  final directories = featuresDirectory
      .listSync(followLinks: false)
      .whereType<Directory>()
      .toList();
  directories.sort((left, right) => left.path.compareTo(right.path));
  return directories;
}

File _file(Directory directory, String name) {
  return File('${directory.path}${Platform.pathSeparator}$name');
}

String? _packageName(File pubspec) {
  if (!pubspec.existsSync()) return null;
  final namePattern = RegExp(r'''^name:\s*['"]?([A-Za-z0-9_-]+)['"]?\s*$''');
  for (final line in pubspec.readAsLinesSync()) {
    final match = namePattern.firstMatch(line.trim());
    if (match != null) return match.group(1);
  }
  return null;
}

bool _hasFlutterDependency(List<String> lines) {
  var inDependencies = false;
  var inFlutter = false;
  for (final line in lines) {
    final trimmed = line.trim();
    if (!line.startsWith(' ') && trimmed.endsWith(':')) {
      inDependencies = trimmed == 'dependencies:';
      inFlutter = false;
      continue;
    }
    if (!inDependencies) continue;
    if (RegExp(r'^  flutter:\s*$').hasMatch(line)) {
      inFlutter = true;
      continue;
    }
    if (inFlutter && RegExp(r'^    sdk:\s*flutter\s*$').hasMatch(line)) {
      return true;
    }
    if (line.startsWith('  ') && !line.startsWith('    ')) {
      inFlutter = false;
    }
  }
  return false;
}

bool _declaresDependency(List<String> lines, String packageName) {
  final dependencyPattern = RegExp(
    r'^  ' + RegExp.escape(packageName) + r':\s*$',
  );
  var inDependencies = false;
  for (final line in lines) {
    final trimmed = line.trim();
    if (!line.startsWith(' ') && trimmed.endsWith(':')) {
      inDependencies = trimmed == 'dependencies:';
      continue;
    }
    if (inDependencies && dependencyPattern.hasMatch(line)) return true;
  }
  return false;
}

bool _hasPathDependency(
  List<String> lines,
  String packageName,
  Directory featureDirectory,
  Directory rootDirectory,
) {
  final packagePattern = RegExp(r'^  ' + RegExp.escape(packageName) + r':\s*$');
  final expectedPath = _relativePath(rootDirectory, featureDirectory);
  var inDependencies = false;
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final trimmed = line.trim();
    if (!line.startsWith(' ') && trimmed.endsWith(':')) {
      inDependencies = trimmed == 'dependencies:';
      continue;
    }
    if (!inDependencies || !packagePattern.hasMatch(line)) continue;
    for (var next = index + 1; next < lines.length; next++) {
      final dependencyLine = lines[next];
      if (dependencyLine.startsWith('  ') &&
          !dependencyLine.startsWith('    ')) {
        break;
      }
      final pathMatch = RegExp(r'^    path:\s*(.+?)\s*$')
          .firstMatch(dependencyLine);
      if (pathMatch != null) {
        return _normalizePath(pathMatch.group(1)!) == expectedPath;
      }
    }
  }
  return false;
}

String _relativePath(Directory rootDirectory, Directory targetDirectory) {
  final rootPath = rootDirectory.resolveSymbolicLinksSync();
  final targetPath = targetDirectory.resolveSymbolicLinksSync();
  final prefix = '$rootPath${Platform.pathSeparator}';
  if (!targetPath.startsWith(prefix)) return '';
  return _normalizePath(targetPath.substring(prefix.length));
}

String _normalizePath(String path) {
  return path
      .trim()
      .replaceAll(RegExp(r'''^['"]|['"]$'''), '')
      .replaceAll('\\', '/');
}

bool _importsApplicationPackage(
  Directory featureDirectory,
  String applicationPackageUri,
) {
  if (!featureDirectory.existsSync()) return false;
  final dartFiles = featureDirectory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
  return dartFiles.any(
    (file) => file.readAsLinesSync().any(
      (line) => line.contains(applicationPackageUri),
    ),
  );
}

String _directoryName(Directory directory) {
  return directory.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
}

bool _importsFile(List<String> lines, String fileName) {
  final importPattern = RegExp(r'''^import\s+['"]([^'"]+)['"]''');
  return lines.any(
    (line) => importPattern.firstMatch(line.trim())?.group(1) == fileName,
  );
}

void main() {
  final issues = validateFeatureDependencies(
    featuresDirectory: Directory('features'),
    diDirectory: Directory('lib/core/di'),
    appDependenciesFile: File('lib/core/di/app_dependencies.dart'),
    rootPubspecFile: File('pubspec.yaml'),
  );
  if (issues.isEmpty) {
    stdout.writeln('Validação de composição das features concluída.');
    return;
  }

  stderr.writeln('Falha na validação de composição das features:');
  for (final issue in issues) {
    stderr.writeln('- $issue');
  }
  exitCode = 1;
}
