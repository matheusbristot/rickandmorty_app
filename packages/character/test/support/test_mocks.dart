import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

final class MockNetworkClient extends Mock implements NetworkClient {}

void registerCharacterTestFallbacks() {
  registerFallbackValue(Uri.parse('https://example.test'));
}
