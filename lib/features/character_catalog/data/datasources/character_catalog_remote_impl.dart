import 'package:character/character_data.dart';
import 'package:network/network.dart';

import '../../domain/entities/character_filter.dart';
import '../../domain/entities/character_page.dart';
import '../models/character_filter_mapper.dart';
import 'character_catalog_remote.dart';

final class CharacterCatalogRemoteImpl implements CharacterCatalogRemote {
  CharacterCatalogRemoteImpl(this._client);

  final PaginatedClient _client;

  @override
  Future<CharacterPage> fetch(CharacterFilter filter, {Uri? next}) async {
    try {
      final result = await _fetch(filter, next);
      return CharacterPage(
        characters: result.results,
        count: result.info.count,
        next: result.info.next,
      );
    } on NetworkException catch (error) {
      if (error.statusCode == 404 && next == null) {
        return CharacterPage(characters: [], count: 0);
      }
      throw CatalogFailure(
        error.statusCode == 429
            ? CatalogFailureKind.rateLimited
            : CatalogFailureKind.network,
      );
    } on FormatException {
      throw const CatalogFailure(CatalogFailureKind.invalidData);
    } on TypeError {
      throw const CatalogFailure(CatalogFailureKind.invalidData);
    }
  }

  Future<PaginatedResponse<CharacterModel>> _fetch(
    CharacterFilter filter,
    Uri? next,
  ) {
    if (next != null) {
      return _client.getPageUri(next, decodeItem: CharacterModel.fromJson);
    }
    final path = Uri(
      path: 'character',
      queryParameters: characterFilterParameters(filter),
    );
    return _client.getPage(
      path.toString(),
      decodeItem: CharacterModel.fromJson,
    );
  }
}
