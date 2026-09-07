import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/character_list_card.dart';
import '../viewmodels/character_catalog_view_model.dart';
import '../widgets/catalog_feedback.dart';
import '../widgets/character_filters.dart';

final class CharacterCatalogPage extends StatefulWidget {
  const CharacterCatalogPage({required this.viewModel, super.key});
  final CharacterCatalogViewModel viewModel;

  @override
  State<CharacterCatalogPage> createState() => _CharacterCatalogPageState();
}

final class _CharacterCatalogPageState extends State<CharacterCatalogPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.refresh();
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.viewModel,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Personagens'),
        actions: [
          IconButton(
            tooltip: 'Atualizar personagens',
            onPressed: widget.viewModel.state.loading
                ? null
                : widget.viewModel.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: widget.viewModel.refresh,
        child: _content(),
      ),
    ),
  );

  Widget _content() {
    final viewModel = widget.viewModel;
    final state = viewModel.state;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: CharacterFilters(
              filter: viewModel.filter,
              onApply: viewModel.search,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${state.characters.length} de ${state.count} personagens',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: state.characters.length,
            itemBuilder: (_, index) => CharacterListCard(
              key: ValueKey(state.characters[index].id),
              character: state.characters[index],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: CatalogFeedback(
              state: state,
              onRetry: viewModel.retry,
              onMore: viewModel.loadMore,
            ),
          ),
        ),
      ],
    );
  }
}
