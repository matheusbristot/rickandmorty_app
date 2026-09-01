import 'package:flutter/material.dart';

import '../state/episode_screen_state.dart';
import '../viewmodels/episode_view_model.dart';
import 'character_tile.dart';
import 'episode_header.dart';
import 'message_card.dart';
import 'offline_banner.dart';

List<Widget> buildEpisodeStatusSlivers(EpisodeViewModel viewModel) {
  if (viewModel.status == EpisodeStatus.loading) {
    return const [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    ];
  }

  if (viewModel.status == EpisodeStatus.error) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: MessageCard(
            icon: Icons.cloud_off,
            title: 'Não foi possível carregar',
            message: viewModel.errorMessage ?? 'Tente novamente.',
          ),
        ),
      ),
    ];
  }

  final episode = viewModel.episode;
  if (episode == null) {
    return const [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: MessageCard(
            icon: Icons.menu_book_outlined,
            title: 'Pronto para começar?',
            message: 'Os episódios consultados ficam disponíveis para acesso offline.',
          ),
        ),
      ),
    ];
  }

  final characters = viewModel.characters;
  return [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(child: EpisodeHeader(episode: episode)),
    ),
    if (viewModel.isRefreshing)
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(),
              SizedBox(height: 8),
              Text('Atualizando dados online...'),
            ],
          ),
        ),
      )
    else if (viewModel.isFromCache || viewModel.errorMessage != null)
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverToBoxAdapter(
          child: OfflineBanner(
            message:
                viewModel.errorMessage ?? 'Dados carregados do dispositivo.',
          ),
        ),
      ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Text(
          'Personagens (${characters.length})',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.builder(
        itemCount: characters.length,
        itemBuilder: (context, index) => CharacterTile(
          item: characters[index],
          onRetry: () => viewModel.retryCharacter(characters[index].url),
        ),
      ),
    ),
  ];
}
