import '../../domain/entities/character_filter.dart';
import '../../domain/entities/character_page.dart';
import '../../domain/repositories/character_catalog_repository.dart';
import '../datasources/character_catalog_local.dart';
import '../datasources/character_catalog_remote.dart';

final class CharacterCatalogRepositoryImpl
    implements CharacterCatalogRepository {
  CharacterCatalogRepositoryImpl(this._local, this._remote);

  final CharacterCatalogLocal _local;
  final CharacterCatalogRemote _remote;

  @override
  Stream<CharacterPageSnapshot> load(
    CharacterFilter filter, {
    Uri? next,
  }) async* {
    final cached = await _readCache(filter, next);
    if (cached != null) {
      yield CharacterPageSnapshot(page: cached, fromCache: true);
    }
    final page = await _remote.fetch(filter, next: next);
    await _saveCache(filter, page, next);
    yield CharacterPageSnapshot(page: page);
  }

  Future<CharacterPage?> _readCache(CharacterFilter filter, Uri? next) async {
    try {
      return await _local.read(filter, next: next);
    } on Exception {
      return null;
    }
  }

  Future<void> _saveCache(
    CharacterFilter filter,
    CharacterPage page,
    Uri? next,
  ) async {
    try {
      await _local.save(filter, page, next: next);
    } on Exception {
      // Cache is best effort; successful remote results remain usable.
    }
  }
}
