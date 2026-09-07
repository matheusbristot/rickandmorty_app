import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:network/network.dart';

abstract interface class FixtureCharacterPages {
  Future<Map<String, dynamic>> load(Uri uri);
}

final class FixtureCharacterPagesImpl implements FixtureCharacterPages {
  FixtureCharacterPagesImpl(this._bundle, this._root);

  final AssetBundle _bundle;
  final String _root;

  @override
  Future<Map<String, dynamic>> load(Uri uri) async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final files = manifest.listAssets().where(
      (path) => path.startsWith('$_root/characters/') && path.endsWith('.json'),
    );
    final characters = await Future.wait(files.map(_loadCharacter));
    final matches =
        characters.where((item) => _matches(item, uri.queryParameters)).toList()
          ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    return _paginate(matches, uri);
  }

  Map<String, dynamic> _paginate(List<Map<String, dynamic>> matches, Uri uri) {
    final page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
    final current = page < 1 ? 1 : page;
    const size = 2;
    final pages = (matches.length / size).ceil();
    if (matches.isEmpty || current > pages) {
      throw const NetworkException(
        message: 'Nenhum resultado.',
        statusCode: 404,
      );
    }
    return {
      'info': {
        'count': matches.length,
        'pages': pages,
        'next': current < pages ? _link(uri, current + 1) : null,
        'prev': current > 1 ? _link(uri, current - 1) : null,
      },
      'results': matches.skip((current - 1) * size).take(size).toList(),
    };
  }

  Future<Map<String, dynamic>> _loadCharacter(String path) async =>
      jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;

  bool _matches(Map<String, dynamic> item, Map<String, String> query) {
    for (final key in ['name', 'status', 'species', 'type', 'gender']) {
      final expected = query[key]?.toLowerCase();
      if (expected == null || expected.isEmpty) continue;
      final actual = (item[key] as String? ?? '').toLowerCase();
      if (key == 'status' || key == 'gender') {
        if (actual != expected) return false;
      } else if (!actual.contains(expected)) {
        return false;
      }
    }
    return true;
  }

  String _link(Uri uri, int page) => Uri(
    scheme: 'https',
    host: 'fixtures.invalid',
    path: '/api/character',
    queryParameters: {...uri.queryParameters, 'page': '$page'},
  ).toString();
}
