import 'package:character/character.dart';

import 'episode.dart';

sealed class EpisodeLoadEvent {
  const EpisodeLoadEvent();
}

final class EpisodeStarted extends EpisodeLoadEvent {
  const EpisodeStarted(this.episode);

  final Episode episode;
}

final class EpisodeCached extends EpisodeLoadEvent {
  const EpisodeCached(this.episode);

  final Episode episode;
}

final class EpisodeCharacterUpdated extends EpisodeLoadEvent {
  const EpisodeCharacterUpdated(this.characterEvent);

  final CharacterLoadEvent characterEvent;
}

final class EpisodeCompleted extends EpisodeLoadEvent {
  const EpisodeCompleted({required this.episode, required this.hasErrors});

  final Episode episode;
  final bool hasErrors;
}
