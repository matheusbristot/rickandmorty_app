import '../entities/episode_load_event.dart';
import '../repositories/episode_repository.dart';

abstract interface class LoadEpisodeUseCase {
  Stream<EpisodeLoadEvent> execute(int id);
}

final class LoadEpisodeUseCaseImpl implements LoadEpisodeUseCase {
  LoadEpisodeUseCaseImpl(this._repository);

  final EpisodeRepository _repository;

  @override
  Stream<EpisodeLoadEvent> execute(int id) async* {
    final cachedEpisode = await _repository.getCachedEpisode(id);
    if (cachedEpisode != null) yield EpisodeCached(cachedEpisode);

    yield* _repository.fetchEpisode(id);
  }
}
