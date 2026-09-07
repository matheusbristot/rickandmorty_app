import 'package:flutter/material.dart';

import '../viewmodels/episode_view_model.dart';

final class EpisodeSearchField extends StatefulWidget {
  const EpisodeSearchField({required this.viewModel, super.key});

  final EpisodeViewModel viewModel;

  @override
  State<EpisodeSearchField> createState() => _EpisodeSearchFieldState();
}

class _EpisodeSearchFieldState extends State<EpisodeSearchField> {
  late final TextEditingController _controller;

  EpisodeViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: viewModel.episodeInput.value);
    viewModel.episodeInput.addListener(_syncController);
  }

  void _syncController() {
    final value = viewModel.episodeInput.value;
    if (_controller.text == value) return;
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    viewModel.episodeInput.removeListener(_syncController);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: viewModel.episodeInput,
      builder: (context, value, _) {
        final canSearch = value.trim().isNotEmpty;
        return TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Número do episódio',
            hintText: 'Ex.: 1',
            prefixIcon: const Icon(Icons.tag),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: canSearch ? viewModel.search : null,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (input) => viewModel.episodeInput.value = input,
          onSubmitted: (_) => viewModel.search(),
        );
      },
    );
  }
}
