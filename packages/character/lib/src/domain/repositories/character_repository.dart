import '../entities/character.dart';

enum CharacterLoadStatus { loading, loaded, error }

class CharacterLoadEvent {
  const CharacterLoadEvent._({
    required this.url,
    required this.status,
    this.character,
    this.errorMessage,
  });

  factory CharacterLoadEvent.loading({required Uri url}) {
    return CharacterLoadEvent._(url: url, status: CharacterLoadStatus.loading);
  }

  factory CharacterLoadEvent.loaded({
    required Uri url,
    required Character character,
  }) {
    return CharacterLoadEvent._(
      url: url,
      status: CharacterLoadStatus.loaded,
      character: character,
    );
  }

  factory CharacterLoadEvent.error({
    required Uri url,
    required String message,
  }) {
    return CharacterLoadEvent._(
      url: url,
      status: CharacterLoadStatus.error,
      errorMessage: message,
    );
  }

  final Uri url;
  final CharacterLoadStatus status;
  final Character? character;
  final String? errorMessage;
}

abstract interface class CharacterRepository {
  Stream<CharacterLoadEvent> getCharactersByUrls(List<Uri> urls);
}
