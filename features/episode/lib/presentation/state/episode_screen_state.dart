import 'package:character/character.dart';

import '../../domain/entities/episode.dart';
import '../../domain/entities/episode_load_event.dart';

enum EpisodeStatus { idle, loading, loaded, error }

final class CharacterItemState {
  const CharacterItemState({
    required this.url,
    required this.status,
    this.character,
    this.errorMessage,
  });

  final Uri url;
  final CharacterLoadStatus status;
  final Character? character;
  final String? errorMessage;
}

final class EpisodeScreenState {
  const EpisodeScreenState({
    this.status = EpisodeStatus.idle,
    this.episode,
    this.isFromCache = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.characterStates = const {},
  });

  final EpisodeStatus status;
  final Episode? episode;
  final bool isFromCache;
  final bool isRefreshing;
  final String? errorMessage;
  final Map<String, CharacterItemState> characterStates;

  List<CharacterItemState> get characters {
    final sorted = characterStates.values.toList()
      ..sort((first, second) {
        final firstName = first.character?.name.toLowerCase();
        final secondName = second.character?.name.toLowerCase();
        if (firstName == null && secondName == null) return 0;
        if (firstName == null) return 1;
        if (secondName == null) return -1;
        return firstName.compareTo(secondName);
      });
    return List.unmodifiable(sorted);
  }

  EpisodeScreenState beginLoading() {
    return const EpisodeScreenState(status: EpisodeStatus.loading);
  }

  EpisodeScreenState invalid(String message) {
    return EpisodeScreenState(
      status: EpisodeStatus.error,
      errorMessage: message,
    );
  }

  EpisodeScreenState reduce(
    EpisodeLoadEvent event,
    String partialErrorMessage,
  ) {
    switch (event) {
      case EpisodeCached(:final episode):
        return _cachedState(episode);
      case EpisodeStarted(:final episode):
        return _startedState(episode);
      case EpisodeCharacterUpdated(:final characterEvent):
        return _withCharacterEvent(characterEvent, partialErrorMessage);
      case EpisodeCompleted(:final episode, :final hasErrors):
        return _completedState(episode, hasErrors, partialErrorMessage);
    }
  }

  EpisodeScreenState _cachedState(Episode episode) {
    return EpisodeScreenState(
      status: EpisodeStatus.loaded,
      episode: episode,
      isFromCache: true,
      isRefreshing: true,
      characterStates: _cachedCharacters(episode),
    );
  }

  EpisodeScreenState _startedState(Episode episode) {
    return EpisodeScreenState(
      status: EpisodeStatus.loaded,
      episode: episode,
      isRefreshing: true,
      characterStates: {
        for (final url in episode.characterUrls)
          _key(url): CharacterItemState(
            url: url,
            status: CharacterLoadStatus.loading,
          ),
      },
    );
  }

  EpisodeScreenState _completedState(
    Episode episode,
    bool hasErrors,
    String partialErrorMessage,
  ) {
    return EpisodeScreenState(
      status: EpisodeStatus.loaded,
      episode: episode,
      isRefreshing: false,
      errorMessage: hasErrors ? partialErrorMessage : null,
      characterStates: hasErrors || characterStates.isNotEmpty
          ? characterStates
          : _cachedCharacters(episode),
    );
  }

  EpisodeScreenState fail(String message, String cachedMessage) {
    if (episode != null) {
      return EpisodeScreenState(
        status: EpisodeStatus.loaded,
        episode: episode,
        isFromCache: isFromCache,
        errorMessage: cachedMessage,
        characterStates: characterStates,
      );
    }
    return EpisodeScreenState(
      status: EpisodeStatus.error,
      errorMessage: message,
    );
  }

  bool canRetry(Uri url) {
    final item = characterStates[_key(url)];
    return item?.status == CharacterLoadStatus.error;
  }

  EpisodeScreenState retryingCharacter(Uri url) {
    return _replaceCharacter(
      url,
      CharacterItemState(url: url, status: CharacterLoadStatus.loading),
    );
  }

  EpisodeScreenState characterLoaded(
    Uri url,
    Character character,
    String partialErrorMessage,
  ) {
    final next = _replaceCharacter(
      url,
      CharacterItemState(
        url: url,
        status: CharacterLoadStatus.loaded,
        character: character,
      ),
    );
    return EpisodeScreenState(
      status: next.status,
      episode: next.episode?.copyWithCharacters(next._loadedCharacters),
      isFromCache: next.isFromCache,
      isRefreshing: next.isRefreshing,
      errorMessage: next._hasCharacterErrors ? partialErrorMessage : null,
      characterStates: next.characterStates,
    );
  }

  EpisodeScreenState characterFailed(Uri url, String message) {
    return _replaceCharacter(
      url,
      CharacterItemState(
        url: url,
        status: CharacterLoadStatus.error,
        errorMessage: message,
      ),
    );
  }

  EpisodeScreenState _withCharacterEvent(
    CharacterLoadEvent event,
    String partialErrorMessage,
  ) {
    final next = _replaceCharacterEvent(event);
    return _stateAfterCharacterEvent(next, event, partialErrorMessage);
  }

  EpisodeScreenState _replaceCharacterEvent(CharacterLoadEvent event) {
    return _replaceCharacter(
      event.url,
      CharacterItemState(
        url: event.url,
        status: event.status,
        character: event.character,
        errorMessage: event.errorMessage,
      ),
    );
  }

  EpisodeScreenState _stateAfterCharacterEvent(
    EpisodeScreenState next,
    CharacterLoadEvent event,
    String partialErrorMessage,
  ) {
    return EpisodeScreenState(
      status: next.status,
      episode: _episodeAfterCharacterEvent(next, event),
      isFromCache: next.isFromCache,
      isRefreshing: next.isRefreshing,
      errorMessage: next._hasCharacterErrors ? partialErrorMessage : null,
      characterStates: next.characterStates,
    );
  }

  Episode? _episodeAfterCharacterEvent(
    EpisodeScreenState next,
    CharacterLoadEvent event,
  ) {
    if (event.status != CharacterLoadStatus.loaded || event.character == null) {
      return next.episode;
    }
    return next.episode?.copyWithCharacters(next._loadedCharacters);
  }

  EpisodeScreenState _replaceCharacter(Uri url, CharacterItemState item) {
    final characters = {...characterStates, _key(url): item};
    return EpisodeScreenState(
      status: status,
      episode: episode,
      isFromCache: isFromCache,
      isRefreshing: isRefreshing,
      errorMessage: errorMessage,
      characterStates: characters,
    );
  }

  bool get _hasCharacterErrors => characterStates.values.any(
    (item) => item.status == CharacterLoadStatus.error,
  );

  List<Character> get _loadedCharacters => characterStates.values
      .where((item) => item.character != null)
      .map((item) => item.character!)
      .toList(growable: false);

  Map<String, CharacterItemState> _cachedCharacters(Episode cached) {
    return {
      for (final character in cached.characters)
        'cache:${character.id}': CharacterItemState(
          url: Uri(),
          status: CharacterLoadStatus.loaded,
          character: character,
        ),
    };
  }

  static String _key(Uri url) => url.toString();
}
