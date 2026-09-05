import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

final class MockHttpClient extends Mock implements http.Client {}

final class MockNetworkClient extends Mock implements NetworkClient {}

void registerNetworkTestFallbacks() {
  registerFallbackValue(Uri.parse('https://example.test'));
  registerFallbackValue(<String, String>{});
}
