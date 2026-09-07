import '../../domain/entities/character_filter.dart';

Map<String, String> characterFilterParameters(CharacterFilter filter) => {
  if (filter.name.trim().isNotEmpty) 'name': filter.name.trim(),
  if (filter.status != null) 'status': filter.status!.name,
  if (filter.species.trim().isNotEmpty) 'species': filter.species.trim(),
  if (filter.type.trim().isNotEmpty) 'type': filter.type.trim(),
  if (filter.gender != null) 'gender': filter.gender!.name,
};
