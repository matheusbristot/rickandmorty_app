import '../entities/character_filter.dart';
import '../entities/character_page.dart';

abstract interface class CharacterCatalogRepository {
  Stream<CharacterPageSnapshot> load(CharacterFilter filter, {Uri? next});
}
