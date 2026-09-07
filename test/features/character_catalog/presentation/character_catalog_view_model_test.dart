import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_catalog_feature/domain/entities/character_filter.dart';
import 'package:character_catalog_feature/domain/entities/character_page.dart';
import 'package:character_catalog_feature/presentation/viewmodels/character_catalog_view_model.dart';

import '../../../support/test_fixtures.dart';
import '../../../support/test_mocks.dart';

void main() {
  setUpAll(registerTestFallbacks);
  const filter = CharacterFilter();
  late MockLoadCharacterCatalog load;
  late CharacterCatalogViewModelImpl vm;
  setUp(() {
    load = MockLoadCharacterCatalog();
    vm = CharacterCatalogViewModelImpl(load);
  });
  tearDown(() => vm.dispose());

  test('carrega, pagina, evita duplicados e para no fim', () async {
    // Arrange
    final next = Uri.parse('https://example.test/?page=2');
    when(() => load.execute(filter)).thenAnswer(
      (_) => Stream.value(
        CharacterPageSnapshot(page: TestFixtures.catalogPage(next: next)),
      ),
    );
    when(() => load.execute(filter, next: next)).thenAnswer(
      (_) => Stream.value(
        CharacterPageSnapshot(
          page: CharacterPage(
            characters: [
              TestFixtures.character(1, 'Rick'),
              TestFixtures.character(2, 'Morty'),
            ],
            count: 2,
          ),
        ),
      ),
    );

    // Act
    await vm.search(filter);
    await vm.loadMore();
    await vm.loadMore();

    // Assert
    expect(vm.state.characters.map((item) => item.id), [1, 2]);
    expect(vm.state.next, isNull);
    verify(() => load.execute(filter, next: next)).called(1);
  });

  test('descarta resposta antiga após aplicar novos filtros', () async {
    // Arrange
    final old = StreamController<CharacterPageSnapshot>();
    const newer = CharacterFilter(name: 'Morty');
    when(() => load.execute(filter)).thenAnswer((_) => old.stream);
    when(() => load.execute(newer)).thenAnswer(
      (_) => Stream.value(
        CharacterPageSnapshot(
          page: TestFixtures.catalogPage(id: 2, name: 'Morty'),
        ),
      ),
    );

    // Act
    final pending = vm.search(filter);
    await vm.search(newer);
    old.add(CharacterPageSnapshot(page: TestFixtures.catalogPage()));
    await old.close();
    await pending;

    // Assert
    expect(vm.state.characters.single.name, 'Morty');
    expect(vm.filter, same(newer));
    expect(vm.state.loading, isFalse);
  });

  test('não faz nova consulta quando o filtro aplicado é igual', () async {
    // Arrange
    when(() => load.execute(filter)).thenAnswer(
      (_) =>
          Stream.value(CharacterPageSnapshot(page: TestFixtures.catalogPage())),
    );

    // Act
    await vm.search(filter);
    await vm.search(const CharacterFilter());

    // Assert
    verify(() => load.execute(filter)).called(1);
  });

  test(
    'cache e rede substituem a mesma página sem manter itens removidos',
    () async {
      // Arrange
      when(() => load.execute(filter)).thenAnswer(
        (_) => Stream.fromIterable([
          CharacterPageSnapshot(
            page: TestFixtures.catalogPage(id: 1),
            fromCache: true,
          ),
          CharacterPageSnapshot(
            page: TestFixtures.catalogPage(id: 2, name: 'Morty'),
          ),
        ]),
      );

      // Act
      await vm.search(filter);

      // Assert
      expect(vm.state.characters.map((item) => item.id), [2]);
      expect(vm.state.fromCache, isFalse);
    },
  );

  test(
    'falha da próxima página mantém lista e retry repete a URL que falhou',
    () async {
      // Arrange
      final next = Uri.parse('https://example.test/?page=2');
      final later = Uri.parse('https://example.test/?page=3');
      when(() => load.execute(filter)).thenAnswer(
        (_) => Stream.value(
          CharacterPageSnapshot(page: TestFixtures.catalogPage(next: next)),
        ),
      );
      when(() => load.execute(filter, next: next)).thenAnswer(
        (_) => Stream.multi((controller) {
          controller.add(
            CharacterPageSnapshot(
              page: TestFixtures.catalogPage(id: 2, next: later),
              fromCache: true,
            ),
          );
          controller.addError(const CatalogFailure(CatalogFailureKind.network));
          controller.close();
        }),
      );

      // Act
      await vm.search(filter);
      await vm.loadMore();
      final failed = vm.state;
      when(() => load.execute(filter, next: next)).thenAnswer(
        (_) => Stream.value(
          CharacterPageSnapshot(
            page: TestFixtures.catalogPage(id: 3, next: later),
          ),
        ),
      );
      await vm.retry();

      // Assert
      expect(failed.characters.map((item) => item.id), [1, 2]);
      expect(failed.error, isNotNull);
      expect(vm.state.characters.map((item) => item.id), [1, 3]);
      expect(vm.state.error, isNull);
      verify(() => load.execute(filter, next: next)).called(2);
      verifyNever(() => load.execute(filter, next: later));
    },
  );

  test(
    'ignora cliques repetidos durante carregamento da próxima página',
    () async {
      // Arrange
      final next = Uri.parse('https://example.test/?page=2');
      final controller = StreamController<CharacterPageSnapshot>();
      when(() => load.execute(filter)).thenAnswer(
        (_) => Stream.value(
          CharacterPageSnapshot(page: TestFixtures.catalogPage(next: next)),
        ),
      );
      when(() => load.execute(filter, next: next))
          .thenAnswer((_) => controller.stream);

      // Act
      await vm.search(filter);
      final pending = vm.loadMore();
      await vm.loadMore();
      controller.add(
        CharacterPageSnapshot(page: TestFixtures.catalogPage(id: 2)),
      );
      await controller.close();
      await pending;

      // Assert
      verify(() => load.execute(filter, next: next)).called(1);
      expect(vm.state.characters, hasLength(2));
    },
  );

  test('cache continua visível quando atualização falha', () async {
    // Arrange
    when(() => load.execute(filter)).thenAnswer(
      (_) => Stream.multi((controller) {
        controller.add(
          CharacterPageSnapshot(
            page: TestFixtures.catalogPage(),
            fromCache: true,
          ),
        );
        controller.addError(const CatalogFailure(CatalogFailureKind.network));
        controller.close();
      }),
    );

    // Act
    await vm.search(filter);

    // Assert
    expect(vm.state.characters, hasLength(1));
    expect(vm.state.fromCache, isTrue);
    expect(vm.state.loading, isFalse);
    expect(vm.state.error, isNotNull);
  });
}
