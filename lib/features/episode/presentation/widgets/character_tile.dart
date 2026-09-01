import 'package:cached_network_image/cached_network_image.dart';
import 'package:character/character.dart';
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
    final image = character.imageUrl.isEmpty
        ? const CharacterImageFallback()
        : CachedNetworkImage(
            imageUrl: character.imageUrl,
            cacheKey: 'character_${character.id}',
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const CharacterImageFallback(showProgress: true),
            errorWidget: (context, url, error) =>
                const CharacterImageFallback(),
          );
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: SizedBox(width: 54, height: 54, child: ClipOval(child: image)),
        title: Text(
          character.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${character.species} • ${character.status}'),
      ),
    );
  }
}

final class CharacterImageFallback extends StatelessWidget {
  const CharacterImageFallback({this.showProgress = false, super.key});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE6EFED),
      child: Center(
        child: showProgress
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_outline),
      ),
    );
  }
}
