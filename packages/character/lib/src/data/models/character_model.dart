import 'package:network/network.dart';

import '../../domain/entities/character.dart';

final class CharacterModel extends Character {
  const CharacterModel({
    required super.id,
    required super.name,
    required super.status,
    required super.species,
    required super.imageUrl,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json.asInt('id'),
      name: json.asString('name'),
      status: json.asString('status'),
      species: json.asString('species'),
      imageUrl: json.asString('image'),
    );
  }

  factory CharacterModel.fromEntity(Character character) {
    return CharacterModel(
      id: character.id,
      name: character.name,
      status: character.status,
      species: character.species,
      imageUrl: character.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status,
    'species': species,
    'image': imageUrl,
  };
}
