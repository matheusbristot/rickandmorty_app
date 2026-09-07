import 'package:flutter/material.dart';

import '../state/character_catalog_state.dart';

final class CatalogFeedback extends StatelessWidget {
  const CatalogFeedback({
    required this.state,
    required this.onRetry,
    required this.onMore,
    super.key,
  });
  final CharacterCatalogState state;
  final VoidCallback onRetry;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (state.fromCache)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Exibindo dados salvos neste dispositivo.'),
        ),
      if (state.error != null) ...[
        Text(state.error!, textAlign: TextAlign.center),
        OutlinedButton(
          onPressed: state.loading ? null : onRetry,
          child: const Text('Tentar novamente'),
        ),
      ],
      if (state.loading)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (!state.loading && state.next != null)
        FilledButton.tonal(
          onPressed: onMore,
          child: const Text('Carregar mais'),
        ),
      if (!state.loading && state.error == null)
        if (state.characters.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nenhum personagem encontrado. Altere ou limpe os filtros.',
            ),
          )
        else if (state.next == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Fim da lista.'),
          ),
    ],
  );
}
