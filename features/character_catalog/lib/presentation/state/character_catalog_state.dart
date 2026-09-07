import 'package:character/character.dart';

import '../../domain/entities/character_page.dart';

final class CharacterCatalogState {
  CharacterCatalogState({
    List<Character> characters = const [],
    this.count = 0,
    this.next,
    this.loading = false,
    this.fromCache = false,
    this.error,
  }) : characters = List.unmodifiable(characters);

  final List<Character> characters;
  final int count;
  final Uri? next;
  final bool loading;
  final bool fromCache;
  final String? error;

  CharacterCatalogState begin() => CharacterCatalogState(
    characters: characters,
    count: count,
    next: next,
    loading: true,
    fromCache: fromCache,
  );

  CharacterCatalogState accept(CharacterPageSnapshot snapshot) {
    final byId = {for (final item in characters) item.id: item};
    for (final item in snapshot.page.characters) {
      byId[item.id] = item;
    }
    return CharacterCatalogState(
      characters: byId.values.toList(),
      count: snapshot.page.count,
      next: snapshot.page.next,
      loading: true,
      fromCache: fromCache || snapshot.fromCache,
    );
  }

  CharacterCatalogState finish([Object? failure]) => CharacterCatalogState(
    characters: characters,
    count: count,
    next: next,
    fromCache: fromCache,
    error: failure == null ? null : _message(failure),
  );

  static String _message(Object failure) {
    if (failure is CatalogFailure) {
      return switch (failure.kind) {
        CatalogFailureKind.rateLimited =>
          'Muitas consultas. Tente novamente em instantes.',
        CatalogFailureKind.invalidData =>
          'Não foi possível ler os personagens recebidos.',
        CatalogFailureKind.network =>
          'Não foi possível atualizar. Verifique sua conexão.',
      };
    }
    return 'Não foi possível carregar os personagens. Tente novamente.';
  }
}
