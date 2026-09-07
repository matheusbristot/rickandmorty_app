import '../../domain/entities/character_filter.dart';
import '../../domain/entities/character_page.dart';

abstract interface class CharacterCatalogRemote {
  Future<CharacterPage> fetch(CharacterFilter filter, {Uri? next});
}
