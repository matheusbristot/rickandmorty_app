import 'dart:convert';
import 'dart:isolate';

import 'package:cache/cache.dart';
import 'package:rickandmorty_app/features/episode/data/datasources/episode_local_data_source.dart';
import 'package:rickandmorty_app/features/episode/data/models/episode_model.dart';

final class EpisodeLocalDataSourceImpl implements EpisodeLocalDataSource {
  EpisodeLocalDataSourceImpl(this._cache);

  final Cache _cache;

  @override
  Future<EpisodeModel?> getEpisode(int id) async {
    final jsonString = await _cache.getString(_key(id));
    if (jsonString == null) return null;

    try {
      return await Isolate.run(() => _parseEpisode(jsonString));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> saveEpisode(EpisodeModel episode) {
    return _cache.setString(_key(episode.id), jsonEncode(episode.toJson()));
  }

  String _key(int id) => 'episode_$id';

  static EpisodeModel? _parseEpisode(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) return null;
    return EpisodeModel.fromJson(Map<String, dynamic>.from(decoded));
  }
}
