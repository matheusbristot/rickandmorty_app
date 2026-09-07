import '../entities/character_filter.dart';
import '../entities/character_page.dart';
import '../repositories/character_catalog_repository.dart';

abstract interface class LoadCharacterCatalog {
  Stream<CharacterPageSnapshot> execute(CharacterFilter filter, {Uri? next});
}

final class LoadCharacterCatalogImpl implements LoadCharacterCatalog {
  LoadCharacterCatalogImpl(this._repository);

  final CharacterCatalogRepository _repository;

  @override
  Stream<CharacterPageSnapshot> execute(CharacterFilter filter, {Uri? next}) {
    return _repository.load(filter, next: next);
  }
}
