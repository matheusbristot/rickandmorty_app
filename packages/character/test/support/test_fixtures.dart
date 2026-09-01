final class CharacterTestFixtures {
  const CharacterTestFixtures._();

  static Uri characterUrl(int id) =>
      Uri.parse('https://rickandmortyapi.com/api/character/$id');

  static Map<String, dynamic> characterJson(int id, String name) => {
    'id': id,
    'name': name,
    'status': 'Alive',
    'species': 'Human',
    'image': '',
  };
}
