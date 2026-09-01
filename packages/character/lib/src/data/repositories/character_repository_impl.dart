import 'package:network/network.dart';

import '../../domain/entities/character.dart';
import '../../domain/repositories/character_repository.dart';
import '../datasources/character_remote_data_source.dart';

final class CharacterRepositoryImpl implements CharacterRepository {
  CharacterRepositoryImpl(this._remoteDataSource);

  final CharacterRemoteDataSource _remoteDataSource;

  @override
  Stream<CharacterLoadEvent> getCharactersByUrls(List<Uri> urls) async* {
    yield* Stream.fromIterable(urls)
        .map((url) => CharacterLoadEvent.loading(url: url));

    try {
      final characters = await _remoteDataSource.getCharactersByUrls(urls);
      yield* _eventsFromCharacters(urls, characters);
    } on Exception {
      // O endpoint em lote pode falhar por uma URL inválida. O fallback
      // individual preserva o resultado dos personagens que continuam válidos.
      yield* _loadIndividually(urls);
    }
  }

  Stream<CharacterLoadEvent> _eventsFromCharacters(
    List<Uri> urls,
    Map<Uri, Character> characters,
  ) async* {
    for (final url in urls) {
      final character = characters[url];
      if (character == null) {
        yield CharacterLoadEvent.error(
          url: url,
          message: 'Não foi possível carregar este personagem.',
        );
        continue;
      }
      yield CharacterLoadEvent.loaded(url: url, character: character);
    }
  }

  Stream<CharacterLoadEvent> _loadIndividually(List<Uri> urls) async* {
    for (final url in urls) {
      try {
        final character = await _remoteDataSource.getCharacterByUrl(url);
        yield CharacterLoadEvent.loaded(url: url, character: character);
      } on Exception catch (error) {
        yield CharacterLoadEvent.error(url: url, message: _messageFor(error));
      }
    }
  }

  String _messageFor(Exception error) {
    if (error is NetworkException) {
      return 'Não foi possível carregar este personagem.';
    }
    if (error is FormatException) return 'Dados do personagem inválidos.';
    return 'Não foi possível carregar este personagem.';
  }
}
