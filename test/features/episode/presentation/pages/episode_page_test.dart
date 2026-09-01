import 'package:character/character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode_failure.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode_load_event.dart';
import 'package:rickandmorty_app/features/episode/domain/usecases/load_episode_use_case.dart';
import 'package:rickandmorty_app/features/episode/domain/usecases/retry_character_use_case.dart';
import 'package:rickandmorty_app/features/episode/presentation/input/episode_input_parser.dart';
import 'package:rickandmorty_app/features/episode/presentation/messages/episode_message_mapper.dart';
import 'package:rickandmorty_app/features/episode/presentation/viewmodels/episode_view_model.dart';
import 'package:rickandmorty_app/main.dart';

import '../../../../support/test_fixtures.dart';
import '../../../../support/test_mocks.dart';

void main() {
  setUpAll(registerTestFallbacks);

  testWidgets('exibe personagens em ordem alfabética', (tester) async {
    // Arrange
    final repository = MockEpisodeRepository();
    final episode = Episode(
      id: 1,
      name: 'Pilot',
      airDate: 'December 2, 2013',
      code: 'S01E01',
      characters: const [
        Character(
          id: 1,
          name: 'Summer Smith',
          status: 'Alive',
          species: 'Human',
          imageUrl: '',
        ),
        Character(
          id: 2,
          name: 'Beth Smith',
          status: 'Alive',
          species: 'Human',
          imageUrl: '',
        ),
        Character(
          id: 3,
          name: 'Rick Sanchez',
          status: 'Alive',
          species: 'Human',
          imageUrl: '',
        ),
      ],
    );
    when(() => repository.getCachedEpisode(1)).thenAnswer((_) async => null);
    when(() => repository.fetchEpisode(1)).thenAnswer(
      (_) => Stream.fromIterable([
        EpisodeStarted(episode),
        EpisodeCompleted(episode: episode, hasErrors: false),
      ]),
    );

    // Act
    await tester.pumpWidget(MyApp(viewModel: _viewModel(repository)));
    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Pilot'), findsOneWidget);
    expect(find.text('Beth Smith'), findsOneWidget);
    expect(find.text('Rick Sanchez'), findsOneWidget);
    expect(find.text('Summer Smith'), findsOneWidget);
    final names = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(
      names.indexOf('Beth Smith'),
      lessThan(names.indexOf('Rick Sanchez')),
    );
    expect(
      names.indexOf('Rick Sanchez'),
      lessThan(names.indexOf('Summer Smith')),
    );
  });

  testWidgets('mantém o cache quando a rede falha', (tester) async {
    // Arrange
    final cached = Episode(
      id: 2,
      name: 'Lawnmower Dog',
      airDate: 'December 9, 2013',
      code: 'S01E02',
      characters: const [
        Character(
          id: 4,
          name: 'Snuffles',
          status: 'Alive',
          species: 'Animal',
          imageUrl: '',
        ),
      ],
    );
    final repository = MockEpisodeRepository();
    when(() => repository.getCachedEpisode(2)).thenAnswer((_) async => cached);
    when(() => repository.fetchEpisode(2))
        .thenThrow(const EpisodeFailure(EpisodeFailureKind.network));

    // Act
    await tester.pumpWidget(MyApp(viewModel: _viewModel(repository)));
    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Lawnmower Dog'), findsOneWidget);
    expect(
      find.text('Sem conexão. Exibindo a última versão salva.'),
      findsOneWidget,
    );
  });

  testWidgets('não exibe detalhes técnicos quando não há conexão nem cache', (
    tester,
  ) async {
    // Arrange
    final repository = MockEpisodeRepository();
    when(() => repository.getCachedEpisode(3)).thenAnswer((_) async => null);
    when(() => repository.fetchEpisode(3))
        .thenThrow(const EpisodeFailure(EpisodeFailureKind.network));

    // Act
    await tester.pumpWidget(MyApp(viewModel: _viewModel(repository)));
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('SocketException'), findsNothing);
    expect(
      find.text(
        'Não foi possível carregar o episódio. Verifique sua conexão e tente novamente.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tenta novamente o personagem ao tocar no card com falha', (
    tester,
  ) async {
    // Arrange
    final failedUrl = Uri.parse('https://rickandmortyapi.com/api/character/1');
    final episode = Episode(
      id: 4,
      name: 'M. Night Shaym-Aliens!',
      airDate: 'January 13, 2014',
      code: 'S01E04',
      characterUrls: [failedUrl],
      characters: const [],
    );
    final repository = MockEpisodeRepository();
    when(() => repository.getCachedEpisode(4)).thenAnswer((_) async => null);
    when(() => repository.fetchEpisode(4)).thenAnswer(
      (_) => Stream.fromIterable([
        EpisodeStarted(episode),
        EpisodeCharacterUpdated(
          CharacterLoadEvent.error(
            url: failedUrl,
            message: 'Falha ao buscar personagem.',
          ),
        ),
        EpisodeCompleted(episode: episode, hasErrors: true),
      ]),
    );
    when(() => repository.fetchCharacter(failedUrl))
        .thenAnswer((_) async => TestFixtures.character(1, 'Rick Sanchez'));

    // Act
    await tester.pumpWidget(MyApp(viewModel: _viewModel(repository)));
    await tester.enterText(find.byType(TextField), '4');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Personagem indisponível'), findsNothing);
    expect(find.text('Rick Sanchez'), findsOneWidget);
    verify(() => repository.fetchCharacter(failedUrl)).called(1);
  });
}

EpisodeViewModel _viewModel(MockEpisodeRepository repository) {
  return EpisodeViewModelImpl(
    LoadEpisodeUseCaseImpl(repository),
    RetryCharacterUseCaseImpl(repository),
    EpisodeInputParserImpl(),
    EpisodeMessageMapperImpl(),
  );
}
