import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:test/test.dart';

import '../../support/test_mocks.dart';

void main() {
  setUpAll(registerNetworkTestFallbacks);

  test('repete 429 e retorna quando a tentativa seguinte funciona', () async {
    // Arrange
    final httpClient = MockHttpClient();
    final responses = [http.Response('', 429), http.Response('{"id": 1}', 200)];
    var responseIndex = 0;
    when(() => httpClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => responses[responseIndex++]);
    final client = NetworkClientImpl(
      config: const NetworkConfig(
        baseUrl: 'https://example.test/api/',
        maxRetries: 1,
        retryBaseDelay: Duration.zero,
      ),
      httpClient: httpClient,
    );

    // Act
    final result = await client.getJson('character/1');

    // Assert
    expect(result, {'id': 1});
    verify(() => httpClient.get(any(), headers: any(named: 'headers')))
        .called(2);
  });

  test('retorna 429 após esgotar as tentativas', () async {
    // Arrange
    final httpClient = MockHttpClient();
    when(() => httpClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('', 429));
    final client = NetworkClientImpl(
      config: const NetworkConfig(
        baseUrl: 'https://example.test/api/',
        maxRetries: 1,
        retryBaseDelay: Duration.zero,
      ),
      httpClient: httpClient,
    );

    // Act
    final future = client.getJson('character/1');

    // Assert
    await expectLater(
      future,
      throwsA(
        isA<NetworkException>().having(
          (error) => error.statusCode,
          'statusCode',
          429,
        ),
      ),
    );
    verify(() => httpClient.get(any(), headers: any(named: 'headers')))
        .called(2);
  });

  test('não inclui a exception original na mensagem de rede', () async {
    // Arrange
    final httpClient = MockHttpClient();
    when(() => httpClient.get(any(), headers: any(named: 'headers')))
        .thenThrow(StateError('SocketException: Failed host lookup'));
    final client = NetworkClientImpl(
      config: const NetworkConfig(baseUrl: 'https://example.test/api/'),
      httpClient: httpClient,
    );

    // Act
    final future = client.getJson('episode/3');

    // Assert
    await expectLater(
      future,
      throwsA(
        isA<NetworkException>().having(
          (error) => error.message,
          'message',
          'Não foi possível conectar ao servidor.',
        ),
      ),
    );
  });
}
