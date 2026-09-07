import '../../domain/entities/character_filter.dart';
import '../../domain/entities/character_page.dart';

abstract interface class CharacterCatalogLocal {
  Future<CharacterPage?> read(CharacterFilter filter, {Uri? next});
  Future<void> save(CharacterFilter filter, CharacterPage page, {Uri? next});
}
