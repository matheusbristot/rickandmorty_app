import 'dart:convert';

import 'package:cache/cache.dart';
import 'package:character/character_data.dart';

import '../../domain/entities/character_filter.dart';
import '../../domain/entities/character_page.dart';
import '../models/character_filter_mapper.dart';
import 'character_catalog_local.dart';

final class CharacterCatalogLocalImpl implements CharacterCatalogLocal {
  CharacterCatalogLocalImpl(this._cache, {required this.scope});

  final Cache _cache;
  final String scope;

  @override
  Future<CharacterPage?> read(CharacterFilter filter, {Uri? next}) async {
    final value = await _cache.getString(_key(filter, next));
    if (value == null) return null;
    try {
      return _decode(jsonDecode(value));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  CharacterPage _decode(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid cached page.');
    }
    final count = json['count'] as int;
    final link = json['next'] as String?;
    final next = link == null ? null : Uri.parse(link);
    if (count < 0 ||
        (next != null &&
            (!next.hasAuthority ||
                next.host.isEmpty ||
                !['http', 'https'].contains(next.scheme)))) {
      throw const FormatException('Invalid cached page.');
    }
    return CharacterPage(
      count: count,
      next: next,
      characters: (json['characters'] as List)
          .map((item) => CharacterModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<void> save(CharacterFilter filter, CharacterPage page, {Uri? next}) {
    final String key = _key(filter, next);
    return _cache.setString(
      key,
      jsonEncode({
        'count': page.count,
        'next': page.next?.toString(),
        'characters': page.characters
            .map((item) => CharacterModel.fromEntity(item).toJson())
            .toList(),
      }),
    );
  }

  String _key(CharacterFilter filter, Uri? next) =>
      jsonEncode([scope, characterFilterParameters(filter), _pageNumber(next)]);

  int _pageNumber(Uri? next) {
    final page = int.tryParse(next?.queryParameters['page'] ?? '1');
    if (page == null || page < 0) {
      throw const FormatException('Invalid cache page number.');
    }
    return page == 0 ? 1 : page;
  }
}
