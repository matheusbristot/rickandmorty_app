import 'package:flutter_test/flutter_test.dart';
import 'package:rickandmorty_app/features/episode/presentation/input/episode_input_parser.dart';

void main() {
  test('converte um número de episódio válido', () {
    // Arrange
    const input = ' 11 ';
    final parser = EpisodeInputParserImpl();

    // Act
    final result = parser.parse(input);

    // Assert
    expect(result, 11);
  });

  test('rejeita valores vazios, não numéricos e não positivos', () {
    // Arrange
    const invalidInputs = ['', 'abc', '0', '-1'];
    final parser = EpisodeInputParserImpl();

    // Act
    final results = invalidInputs.map(parser.parse).toList();

    // Assert
    expect(results, everyElement(isNull));
  });
}
