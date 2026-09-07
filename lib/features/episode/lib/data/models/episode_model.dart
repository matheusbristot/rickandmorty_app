import 'package:character/character_data.dart';
import 'package:network/network.dart';

import '../../domain/entities/episode.dart';

final class EpisodeModel extends Episode {
  EpisodeModel({
    required super.id,
    required super.name,
    required super.airDate,
    required super.code,
    required super.characters,
    super.characterUrls,
  });

  factory EpisodeModel.fromJson(
    Map<String, dynamic> json, {
    List<Character>? characters,
  }) {
    final characterJson = json['characters'];
    final characterUrls =
        (json['character_urls'] as List? ??
                (characterJson is List ? characterJson : const []))
            .whereType<String>()
            .map(Uri.parse)
            .toList(growable: false);
    final parsedCharacters =
        characters ??
        (characterJson is List
            ? characterJson
                  .whereType<Map>()
                  .map(
                    (item) => CharacterModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList()
            : <CharacterModel>[]);

    return EpisodeModel(
      id: json.asInt('id'),
      name: json.asString('name'),
      airDate: json.asString('air_date'),
      code: json.asString('episode'),
      characters: parsedCharacters,
      characterUrls: characterUrls,
    );
  }

  factory EpisodeModel.fromEntity(Episode episode) {
    return EpisodeModel(
      id: episode.id,
      name: episode.name,
      airDate: episode.airDate,
      code: episode.code,
      characters: episode.characters
          .map(CharacterModel.fromEntity)
          .toList(growable: false),
      characterUrls: episode.characterUrls,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'air_date': airDate,
    'episode': code,
    'character_urls': characterUrls.map((url) => url.toString()).toList(),
    'characters': characters
        .map((character) => CharacterModel.fromEntity(character).toJson())
        .toList(growable: false),
  };
}
