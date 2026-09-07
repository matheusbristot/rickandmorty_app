import 'package:character/character.dart';
import 'package:flutter/material.dart';

import 'character_avatar.dart';

final class CharacterListCard extends StatelessWidget {
  const CharacterListCard({required this.character, super.key});

  final Character character;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CharacterAvatar(character: character),
      title: Text(
        character.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${character.species} • ${_statusLabel(character.status)}',
      ),
    ),
  );

  String _statusLabel(String status) => switch (status.toLowerCase()) {
    'alive' => 'Vivo',
    'dead' => 'Morto',
    _ => 'Status desconhecido',
  };
}
