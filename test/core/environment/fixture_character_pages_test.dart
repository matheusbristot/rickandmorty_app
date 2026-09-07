import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:rickandmorty_app/core/environment/fixture_network_client_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final environment in ['dev', 'stg']) {
    test('pagina e filtra fixtures $environment', () async {
      // Arrange
      final client = PaginatedClientImpl(
        FixtureNetworkClientImpl(fixtureRoot: 'assets/fixtures/$environment'),
      );

      // Act
      final first = await client.getPage(
        'character',
        decodeItem: (json) => json,
      );
      final second = await client.getPageUri(
        first.info.next!,
        decodeItem: (json) => json,
      );
      final filtered = await client.getPage(
        'character?name=rick&status=alive&species=Human&gender=male',
        decodeItem: (json) => json,
      );

      // Assert
      expect(first.results, hasLength(2));
      expect(first.info.count, 3);
      expect(second.results, hasLength(1));
      expect(second.info.next, isNull);
      expect(filtered.results.single['id'], 1);
    });
  }

  test('filtros sem correspondência retornam 404 da fixture', () async {
    // Arrange
    final client = FixtureNetworkClientImpl(fixtureRoot: 'assets/fixtures/dev');

    // Act
    final future = client.getJson('character?type=absent');

    // Assert
    await expectLater(
      future,
      throwsA(
        isA<NetworkException>().having(
          (error) => error.statusCode,
          'status',
          404,
        ),
      ),
    );
  });
}
