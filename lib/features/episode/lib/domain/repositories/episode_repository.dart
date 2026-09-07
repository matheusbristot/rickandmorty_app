import 'package:character/character.dart';

import '../entities/episode.dart';
import '../entities/episode_load_event.dart';

abstract interface class EpisodeRepository {
  Future<Episode?> getCachedEpisode(int id);

  Stream<EpisodeLoadEvent> fetchEpisode(int id);

  Future<Character> fetchCharacter(Uri url);
}
