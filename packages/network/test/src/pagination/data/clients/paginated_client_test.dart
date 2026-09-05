import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:test/test.dart';

import '../../../../support/test_fixtures.dart';
import '../../../../support/test_mocks.dart';

void main() {
  late MockNetworkClient network;
  late PaginatedClient client;
  setUpAll(registerNetworkTestFallbacks);
  setUp(() {
    network = MockNetworkClient();
    client = PaginatedClientImpl(network);
  });

  for (final resource in ['character', 'location', 'episode']) {
    for (final page in [0, 1, 2, 42]) {
      test('loads $resource page $page', () async {
        // Arrange
        final expected = '$resource?page=${page == 0 ? 1 : page}';
        when(() => network.getJson(expected))
            .thenAnswer((_) async => paginatedJson());

        // Act
        final result = await client.getPage<int>(
          resource,
          page: page,
          decodeItem: (json) => json['id'] as int,
        );

        // Assert
        expect(result.results, [1]);
        verify(() => network.getJson(expected)).called(1);
        verifyNoMoreInteractions(network);
      });
    }
  }

  test(
    'defaults to page one and preserves repeated and encoded filters',
    () async {
      // Arrange
      when(() => network.getJson(any()))
          .thenAnswer((_) async => paginatedJson());

      // Act
      await client.getPage<String>(
        'character?name=Rick%20Sanchez&tag=a&tag=b&page=8',
        decodeItem: (json) => json['name'] as String,
      );

      // Assert
      final path =
          verify(() => network.getJson(captureAny())).captured.single as String;
      expect(Uri.parse(path).queryParametersAll, {
        'name': ['Rick Sanchez'],
        'tag': ['a', 'b'],
        'page': ['1'],
      });
    },
  );

  test('rejects negative pages before I/O', () async {
    // Arrange
    const page = -1;

    // Act
    final future = client.getPage<int>(
      'character',
      page: page,
      decodeItem: (_) => 1,
    );

    // Assert
    await expectLater(future, throwsArgumentError);
    verifyZeroInteractions(network);
  });

  for (final path in [
    'https://example.test/api',
    '//example.test/api',
    'character#page',
  ]) {
    test('rejects non-relative or fragmented path $path', () async {
      // Arrange
      final invalidPath = path;

      // Act
      final future = client.getPage<int>(invalidPath, decodeItem: (_) => 1);

      // Assert
      await expectLater(future, throwsArgumentError);
      verifyZeroInteractions(network);
    });
  }

  test('follows returned next and previous links unchanged', () async {
    // Arrange
    final next = Uri.parse(
      'https://example.test/api/character/?page=3&name=Rick%20Sanchez',
    );
    final prev = Uri.parse(
      'https://example.test/api/character/?page=1&name=Rick%20Sanchez',
    );
    when(() => network.getJson(any()))
        .thenAnswer((_) async => paginatedJson(next: '$next', prev: '$prev'));
    when(() => network.getJsonUri(any()))
        .thenAnswer((_) async => paginatedJson());

    // Act
    final page = await client.getPage<int>(
      'character',
      page: 2,
      decodeItem: (_) => 1,
    );
    await client.getPageUri<int>(page.info.next!, decodeItem: (_) => 1);
    await client.getPageUri<int>(page.info.prev!, decodeItem: (_) => 1);

    // Assert
    verify(() => network.getJson('character?page=2')).called(1);
    verify(() => network.getJsonUri(next)).called(1);
    verify(() => network.getJsonUri(prev)).called(1);
    verifyNoMoreInteractions(network);
  });

  for (final value in [
    '/api/character',
    'ftp://example.test/file',
    'https://',
  ]) {
    test('rejects invalid page URL $value before I/O', () async {
      // Arrange
      final uri = Uri.parse(value);

      // Act
      final future = client.getPageUri<int>(uri, decodeItem: (_) => 1);

      // Assert
      await expectLater(future, throwsArgumentError);
      verifyZeroInteractions(network);
    });
  }

  for (final status in [null, 404, 429, 500]) {
    test(
      'preserves network failure $status through both entry points',
      () async {
        // Arrange
        final error = NetworkException(message: 'Failure', statusCode: status);
        final uri = Uri.parse('https://example.test/api/character?page=2');
        when(() => network.getJson(any())).thenThrow(error);
        when(() => network.getJsonUri(uri)).thenThrow(error);

        // Act
        final byPath = client.getPage<int>('character', decodeItem: (_) => 1);
        final byUri = client.getPageUri<int>(uri, decodeItem: (_) => 1);

        // Assert
        await expectLater(byPath, throwsA(same(error)));
        await expectLater(byUri, throwsA(same(error)));
        verify(() => network.getJson('character?page=1')).called(1);
        verify(() => network.getJsonUri(uri)).called(1);
      },
    );
  }

  test(
    'keeps concurrent responses independent when they finish out of order',
    () async {
      // Arrange
      final first = Completer<Object?>();
      final second = Completer<Object?>();
      when(() => network.getJson('character?page=1'))
          .thenAnswer((_) => first.future);
      when(() => network.getJson('character?page=2'))
          .thenAnswer((_) => second.future);

      // Act
      final request1 = client.getPage<int>(
        'character',
        decodeItem: (json) => json['id'] as int,
      );
      final request2 = client.getPage<int>(
        'character',
        page: 2,
        decodeItem: (json) => json['id'] as int,
      );
      second.complete(
        paginatedJson(
          results: [
            {'id': 2},
          ],
        ),
      );
      final page2 = await request2;
      first.complete(
        paginatedJson(
          results: [
            {'id': 1},
          ],
        ),
      );
      final page1 = await request1;

      // Assert
      expect(page1.results, [1]);
      expect(page2.results, [2]);
      verify(() => network.getJson('character?page=1')).called(1);
      verify(() => network.getJson('character?page=2')).called(1);
      verifyNoMoreInteractions(network);
    },
  );
}
