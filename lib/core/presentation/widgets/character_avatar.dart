import 'package:cached_network_image/cached_network_image.dart';
import 'package:character/character.dart';
import 'package:flutter/material.dart';

import 'character_image_fallback.dart';

final class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({required this.character, this.size = 56, super.key});

  final Character character;
  final double size;

  @override
  Widget build(BuildContext context) {
    const fallback = CharacterImageFallback();
    final image = character.imageUrl.isEmpty
        ? fallback
        : CachedNetworkImage(
            imageUrl: character.imageUrl,
            cacheKey: 'character_${character.id}',
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                const CharacterImageFallback(showProgress: true),
            errorWidget: (_, _, _) => fallback,
          );

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: image),
    );
  }
}
