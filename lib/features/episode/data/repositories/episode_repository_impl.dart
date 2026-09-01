import 'package:character/character.dart';
import 'package:network/network.dart';

import '../../domain/entities/episode.dart';
import '../../domain/entities/episode_failure.dart';
import '../../domain/entities/episode_load_event.dart';
import '../../domain/repositories/episode_repository.dart';
import '../datasources/episode_local_data_source.dart';
import '../datasources/episode_remote_data_source.dart';
import '../models/episode_model.dart';

final class EpisodeRepositoryImpl implements EpisodeRepository {
  EpisodeRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._characterRepository,
  );

  final EpisodeLocalDataSource _localDataSource;
  final EpisodeRemoteDataSource _remoteDataSource;
  final CharacterRepository _characterRepository;

  @override
  Future<Episode?> getCachedEpisode(int id) => _localDataSource.getEpisode(id);

  @override
  Future<Character> fetchCharacter(Uri url) async {
    await for (final event in _characterRepository.getCharactersByUrls([url])) {
      if (event.status == CharacterLoadStatus.loaded &&
          event.character != null) {
        return event.character!;
      }
      if (event.status == CharacterLoadStatus.error) {
        throw NetworkException(
          message:
              event.errorMessage ??
              'Não foi possível carregar este personagem.',
        );
      }
    }

    throw const NetworkException(
      message: 'Não foi possível carregar este personagem.',
    );
  }

  @override
  Stream<EpisodeLoadEvent> fetchEpisode(int id) async* {
    final episode = await _loadRemoteEpisode(id);
    yield EpisodeStarted(episode);

    final loadedCharacters = <Character>[];
    var hasErrors = false;
    await for (final event in _characterRepository.getCharactersByUrls(
      episode.characterUrls,
    )) {
      if (event.status == CharacterLoadStatus.loaded &&
          event.character != null) {
        loadedCharacters.add(event.character!);
      }
      if (event.status == CharacterLoadStatus.error) hasErrors = true;
      yield EpisodeCharacterUpdated(event);
    }

    final completedEpisode = episode.copyWithCharacters(loadedCharacters);
    await _localDataSource.saveEpisode(
      EpisodeModel.fromEntity(completedEpisode),
    );
    yield EpisodeCompleted(episode: completedEpisode, hasErrors: hasErrors);
  }

  Future<EpisodeModel> _loadRemoteEpisode(int id) async {
    try {
      return await _remoteDataSource.getEpisode(id);
    } on NetworkException catch (error) {
      throw EpisodeFailure(_failureKindFor(error.statusCode));
    } on FormatException {
      throw const EpisodeFailure(EpisodeFailureKind.invalidData);
    }
  }

  EpisodeFailureKind _failureKindFor(int? statusCode) {
    return switch (statusCode) {
      404 => EpisodeFailureKind.notFound,
      429 => EpisodeFailureKind.tooManyRequests,
      _ => EpisodeFailureKind.network,
    };
  }
}
