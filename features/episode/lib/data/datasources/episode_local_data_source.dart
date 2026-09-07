import '../models/episode_model.dart';

abstract interface class EpisodeLocalDataSource {
  Future<EpisodeModel?> getEpisode(int id);

  Future<void> saveEpisode(EpisodeModel episode);
}
