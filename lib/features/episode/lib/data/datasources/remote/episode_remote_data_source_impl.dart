import 'dart:isolate';

import 'package:network/network.dart';

import '../../models/episode_model.dart';
import '../episode_remote_data_source.dart';

final class EpisodeRemoteDataSourceImpl implements EpisodeRemoteDataSource {
  EpisodeRemoteDataSourceImpl(this._client);

  final NetworkClient _client;

  @override
  Future<EpisodeModel> getEpisode(int id) async {
    final episodeJson = await _client.getJson('episode/$id');
    return await Isolate.run(() => _parseEpisode(episodeJson));
  }

  static EpisodeModel _parseEpisode(Object? episodeJson) {
    if (episodeJson is! Map) {
      throw const FormatException('Episódio inválido.');
    }

    final episodeMap = Map<String, dynamic>.from(episodeJson);
    return EpisodeModel.fromJson(episodeMap, characters: const []);
  }
}
