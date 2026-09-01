import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:network/network.dart';

final class FixtureNetworkClientImpl implements NetworkClient {
  FixtureNetworkClientImpl({required this.fixtureRoot, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final String fixtureRoot;
  final AssetBundle _bundle;

  @override
  Future<dynamic> getJson(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return _getResource(Uri(path: normalizedPath));
  }

  @override
  Future<dynamic> getJsonUri(Uri uri) => _getResource(uri);

  @override
  void close() {}

  Future<dynamic> _getResource(Uri uri) {
    final segments = uri.pathSegments;
    final resourceIndex = _resourceIndex(segments);
    if (resourceIndex < 0 || resourceIndex + 1 >= segments.length) {
      throw const FormatException('URL de fixture inválida.');
    }

    final resource = segments[resourceIndex];
    final ids = segments[resourceIndex + 1].split(',');
    return resource == 'character' && ids.length > 1
        ? _loadCharacters(ids)
        : _loadAsset('${_directoryFor(resource)}/${ids.single}.json');
  }

  int _resourceIndex(List<String> segments) {
    final episodeIndex = segments.lastIndexOf('episode');
    final characterIndex = segments.lastIndexOf('character');
    return episodeIndex > characterIndex ? episodeIndex : characterIndex;
  }

  Future<List<dynamic>> _loadCharacters(List<String> ids) async {
    return Future.wait(ids.map((id) => _loadAsset('characters/$id.json')));
  }

  String _directoryFor(String resource) {
    return resource == 'episode' ? 'episodes' : 'characters';
  }

  Future<dynamic> _loadAsset(String relativePath) async {
    try {
      final json = await _bundle.loadString('$fixtureRoot/$relativePath');
      return jsonDecode(json);
    } on FormatException {
      throw const FormatException('Fixture JSON inválido.');
    } on NetworkException {
      rethrow;
    } catch (_) {
      throw const NetworkException(
        message: 'Fixture não encontrada.',
        statusCode: 404,
      );
    }
  }
}
