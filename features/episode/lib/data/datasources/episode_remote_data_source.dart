import '../models/episode_model.dart';

abstract interface class EpisodeRemoteDataSource {
  Future<EpisodeModel> getEpisode(int id);
}
