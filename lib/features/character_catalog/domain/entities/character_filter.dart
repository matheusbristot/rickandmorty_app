enum CharacterStatus { alive, dead, unknown }

enum CharacterGender { female, male, genderless, unknown }

final class CharacterFilter {
  const CharacterFilter({
    this.name = '',
    this.status,
    this.species = '',
    this.type = '',
    this.gender,
  });

  final String name;
  final CharacterStatus? status;
  final String species;
  final String type;
  final CharacterGender? gender;

  bool get isEmpty =>
      name.trim().isEmpty &&
      species.trim().isEmpty &&
      type.trim().isEmpty &&
      status == null &&
      gender == null;

  @override
  bool operator ==(Object other) {
    return other is CharacterFilter &&
        other.name.trim() == name.trim() &&
        other.status == status &&
        other.species.trim() == species.trim() &&
        other.type.trim() == type.trim() &&
        other.gender == gender;
  }

  @override
  int get hashCode =>
      Object.hash(name.trim(), status, species.trim(), type.trim(), gender);
}
