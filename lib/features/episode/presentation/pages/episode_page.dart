import 'package:flutter/material.dart';

import '../viewmodels/episode_view_model.dart';
import '../widgets/episode_search_field.dart';
import '../widgets/episode_status_slivers.dart';

final class EpisodePage extends StatefulWidget {
  const EpisodePage({required this.viewModel, super.key});

  final EpisodeViewModel viewModel;

  @override
  State<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends State<EpisodePage> {
  EpisodeViewModel get viewModel => widget.viewModel;

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rick & Morty Episodes')),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore um episódio',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Informe o número para ver a aventura e todos os personagens.',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      EpisodeSearchField(viewModel: viewModel),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              ...buildEpisodeStatusSlivers(viewModel),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
