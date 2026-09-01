import 'package:network/network.dart';

import '../../models/character_model.dart';
import '../character_remote_data_source.dart';

final class CharacterRemoteDataSourceImpl implements CharacterRemoteDataSource {
  CharacterRemoteDataSourceImpl(this._client);

  final NetworkClient _client;

  @override
  Future<CharacterModel> getCharacterByUrl(Uri url) async {
    final json = await _client.getJsonUri(url);
    if (json is! Map) {
      throw const FormatException('Personagem inválido.');
    }
    return CharacterModel.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<Map<Uri, CharacterModel>> getCharactersByUrls(List<Uri> urls) async {
    if (urls.isEmpty) return const {};

    final ids = urls.map(_characterId).toSet().join(',');
    final json = await _client.getJsonUri(_batchUri(urls.first, ids));
    final items = json is List
        ? json
        : urls.length == 1 && json is Map
        ? [json]
        : throw const FormatException('Personagens inválidos.');

    final charactersById = <int, CharacterModel>{};
    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Personagem inválido.');
      }
      final character = CharacterModel.fromJson(
        Map<String, dynamic>.from(item),
      );
      charactersById[character.id] = character;
    }

    final charactersByUrl = <Uri, CharacterModel>{};
    for (final url in urls) {
      final character = charactersById[_characterId(url)];
      if (character != null) charactersByUrl[url] = character;
    }
    return charactersByUrl;
  }

  int _characterId(Uri url) {
    final segments = url.pathSegments.where((segment) => segment.isNotEmpty);
    final id = segments.isEmpty ? null : int.tryParse(segments.last);
    if (id == null) throw const FormatException('URL de personagem inválida.');
    return id;
  }

  Uri _batchUri(Uri reference, String ids) {
    final segments = reference.pathSegments;
    final characterIndex = segments.lastIndexOf('character');
    if (characterIndex < 0) {
      throw const FormatException('URL de personagem inválida.');
    }

    return reference.replace(
      path: '/${[...segments.take(characterIndex + 1), ids].join('/')}',
    );
  }
}
