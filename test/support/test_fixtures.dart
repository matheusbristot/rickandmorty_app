import 'package:character/character.dart';
import 'package:character_catalog_feature/domain/entities/character_page.dart';
import 'package:episode_feature/data/models/episode_model.dart';
import 'package:episode_feature/domain/entities/episode.dart';

final class TestFixtures {
  const TestFixtures._();

  static CharacterPage catalogPage({
    int id = 1,
    String name = 'Rick Sanchez',
    Uri? next,
    int count = 3,
  }) => CharacterPage(
    characters: [character(id, name)],
    count: count,
    next: next,
  );

  static Uri characterUrl(int id) =>
      Uri.parse('https://rickandmortyapi.com/api/character/$id');

  static Character character(int id, String name) => Character(
    id: id,
    name: name,
    status: 'Alive',
    species: 'Human',
    imageUrl: '',
  );

  static Episode episode(
    String name, {
    int id = 1,
    List<Uri> characterUrls = const [],
    List<Character> characters = const [],
  }) {
    return Episode(
      id: id,
      name: name,
      airDate: 'December 2, 2013',
      code: 'S01E01',
      characterUrls: characterUrls,
      characters: characters,
    );
  }

  static EpisodeModel episodeModel({
    int id = 3,
    String name = 'Anatomy Park',
    List<Uri> characterUrls = const [],
    List<Character> characters = const [],
  }) {
    return EpisodeModel(
      id: id,
      name: name,
      airDate: 'December 16, 2013',
      code: 'S01E03',
      characterUrls: characterUrls,
      characters: characters,
    );
  }

  static Map<String, dynamic> episodeJson(
    List<Uri> characterUrls, {
    int id = 3,
    String name = 'Anatomy Park',
  }) {
    return {
      'id': id,
      'name': name,
      'air_date': 'December 16, 2013',
      'episode': 'S01E03',
      'characters': characterUrls.map((url) => url.toString()).toList(),
    };
  }

  static Map<String, dynamic> characterJson(int id, String name) => {
    'id': id,
    'name': name,
    'status': 'Alive',
    'species': 'Human',
    'image': '',
  };
}
