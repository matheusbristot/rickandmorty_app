import 'package:character/character.dart';

final class CharacterPage {
  CharacterPage({
    required List<Character> characters,
    required this.count,
    this.next,
  }) : characters = List.unmodifiable(characters);

  final List<Character> characters;
  final int count;
  final Uri? next;
}

final class CharacterPageSnapshot {
  const CharacterPageSnapshot({required this.page, this.fromCache = false});

  final CharacterPage page;
  final bool fromCache;
}

enum CatalogFailureKind { network, invalidData, rateLimited }

final class CatalogFailure implements Exception {
  const CatalogFailure(this.kind);

  final CatalogFailureKind kind;
}
