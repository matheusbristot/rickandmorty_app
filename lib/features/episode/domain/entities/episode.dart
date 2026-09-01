import 'package:character/character.dart';

class Episode {
  Episode({
    required this.id,
    required this.name,
    required this.airDate,
    required this.code,
    required List<Character> characters,
    this.characterUrls = const [],
  }) : characters = List.unmodifiable(
         [...characters]..sort(
           (first, second) =>
               first.name.toLowerCase().compareTo(second.name.toLowerCase()),
         ),
       );

  final int id;
  final String name;
  final String airDate;
  final String code;
  final List<Character> characters;
  final List<Uri> characterUrls;

  Episode copyWithCharacters(List<Character> newCharacters) {
    return Episode(
      id: id,
      name: name,
      airDate: airDate,
      code: code,
      characters: newCharacters,
      characterUrls: characterUrls,
    );
  }
}
