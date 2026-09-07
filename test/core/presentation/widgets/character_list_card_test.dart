import 'package:app_ui/app_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:character/character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('padroniza os dados e o fallback visual do personagem', (
    tester,
  ) async {
    // Arrange
    const character = Character(
      id: 1,
      name: 'Rick Sanchez',
      status: 'Alive',
      species: 'Human',
      imageUrl: '',
    );

    // Act
    await tester.pumpWidget(
      const MaterialApp(home: CharacterListCard(character: character)),
    );

    // Assert
    expect(find.text('Rick Sanchez'), findsOneWidget);
    expect(find.text('Human • Vivo'), findsOneWidget);
    expect(find.byType(CharacterAvatar), findsOneWidget);
    expect(find.byType(CharacterImageFallback), findsOneWidget);
  });

  testWidgets('usa CachedNetworkImage para imagens remotas', (tester) async {
    // Arrange
    const character = Character(
      id: 2,
      name: 'Morty Smith',
      status: 'Dead',
      species: 'Human',
      imageUrl: 'https://example.test/morty.png',
    );

    // Act
    await tester.pumpWidget(
      const MaterialApp(home: CharacterListCard(character: character)),
    );

    // Assert
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.cacheKey, 'character_2');
    expect(find.text('Human • Morto'), findsOneWidget);
  });
}
