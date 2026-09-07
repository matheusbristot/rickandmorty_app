import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickandmorty_app/features/character_catalog/domain/entities/character_filter.dart';
import 'package:rickandmorty_app/features/character_catalog/presentation/widgets/character_filters.dart';

void main() {
  testWidgets('combina cinco filtros e limpa valores e seleções', (
    tester,
  ) async {
    // Arrange
    final applied = <CharacterFilter>[];
    tester.view.physicalSize = const Size(500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CharacterFilters(onApply: applied.add),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Rick');
    await tester.enterText(find.byType(TextField).at(1), 'Human');
    await tester.enterText(find.byType(TextField).at(2), 'Clone');
    await tester.tap(find.byType(DropdownButtonFormField<CharacterStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vivo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<CharacterGender>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masculino').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Status: Vivo'), findsOneWidget);
    expect(find.text('Gênero: Masculino'), findsOneWidget);
    expect(find.text('Espécie: Human'), findsOneWidget);
    expect(find.text('Tipo: Clone'), findsOneWidget);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    // Assert
    expect(applied.first.name, 'Rick');
    expect(applied.first.species, 'Human');
    expect(applied.first.type, 'Clone');
    expect(applied.first.status, CharacterStatus.alive);
    expect(applied.first.gender, CharacterGender.male);
    expect(applied.last.name, isEmpty);
    expect(applied.last.species, isEmpty);
    expect(applied.last.type, isEmpty);
    expect(applied.last.status, isNull);
    expect(applied.last.gender, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fechar ou aplicar filtro vazio não emite aplicação', (
    tester,
  ) async {
    // Arrange
    final applied = <CharacterFilter>[];

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CharacterFilters(onApply: applied.add)),
      ),
    );
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    // Assert
    expect(applied, isEmpty);
  });

  testWidgets('aplicar novamente os mesmos filtros apenas fecha o sheet', (
    tester,
  ) async {
    // Arrange
    const filter = CharacterFilter(status: CharacterStatus.alive);
    final applied = <CharacterFilter>[];

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterFilters(filter: filter, onApply: applied.add),
        ),
      ),
    );
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    // Assert
    expect(applied, isEmpty);
    expect(find.text('Status: Vivo'), findsOneWidget);
  });
}
