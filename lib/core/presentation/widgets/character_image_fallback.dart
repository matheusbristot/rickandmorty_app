import 'package:flutter/material.dart';

final class CharacterImageFallback extends StatelessWidget {
  const CharacterImageFallback({this.showProgress = false, super.key});

  final bool showProgress;

  @override
  Widget build(BuildContext context) => ColoredBox(
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
