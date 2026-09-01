import 'package:network/network.dart';
import 'package:test/test.dart';

void main() {
  test('converte campos JSON sem depender do Flutter', () {
    // Arrange
    final json = <String, dynamic>{'id': '11', 'name': 'Rick Sanchez'};

    // Act
    final id = json.asInt('id');
    final name = json.asString('name');

    // Assert
    expect(id, 11);
    expect(name, 'Rick Sanchez');
  });

  test('converte valores JSON inteiros e textuais de forma reutilizável', () {
    // Arrange
    final json = <String, dynamic>{
      'integer': 11,
      'numericText': '30',
      'name': 'Rick Sanchez',
      'missing': null,
    };

    // Act
    final integer = json.asInt('integer');
    final numericText = json.asInt('numericText');
    final name = json.asString('name');
    final missing = json.asString('missing');

    // Assert
    expect(integer, 11);
    expect(numericText, 30);
    expect(name, 'Rick Sanchez');
    expect(missing, isEmpty);
  });
}
