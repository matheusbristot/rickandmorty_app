import 'package:character/character.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../state/episode_screen_state.dart';

final class CharacterTile extends StatelessWidget {
  const CharacterTile({required this.item, required this.onRetry, super.key});

  final CharacterItemState item;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (item.status == CharacterLoadStatus.loading) {
      return const Card(
        margin: EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: SizedBox(
            width: 54,
            height: 54,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          title: Text('Carregando personagem...'),
          subtitle: Text('Buscando informações do personagem.'),
        ),
      );
    }

    if (item.status == CharacterLoadStatus.error || item.character == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          onTap: item.url == Uri() ? null : onRetry,
          leading: const CircleAvatar(child: Icon(Icons.person_off_outlined)),
          title: const Text('Personagem indisponível'),
          subtitle: const Text('Não foi possível carregar este personagem.'),
          trailing: const Icon(Icons.refresh),
        ),
      );
    }

    final character = item.character!;
    return CharacterListCard(character: character);
  }
}
