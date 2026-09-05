import 'package:network/network_entities.dart';
import 'package:network/src/pagination/data/mappers/paginated_response_mapper.dart';
import 'package:network/src/pagination/data/mappers/pagination_info_mapper.dart';
import 'package:test/test.dart';

import '../../../../support/test_fixtures.dart';

void main() {
  for (final scenario in [
    (
      name: 'first',
      next: 'https://example.test/api/character?page=2',
      prev: null,
    ),
    (
      name: 'middle',
      next: 'https://example.test/api/character?page=3',
      prev: 'https://example.test/api/character?page=1',
    ),
    (
      name: 'last',
      next: null,
      prev: 'https://example.test/api/character?page=41',
    ),
    (name: 'only', next: null, prev: null),
  ]) {
    test('decodes ${scenario.name} page metadata and items', () {
      // Arrange
      final count = scenario.name == 'only' ? 1 : 826;
      final pages = scenario.name == 'only' ? 1 : 42;
      final json = paginatedJson(
        count: count,
        pages: pages,
        next: scenario.next,
        prev: scenario.prev,
      );

      // Act
      final result = PaginatedResponseMapper.fromJson<String>(
        json,
        decodeItem: (item) => item['name'] as String,
      );

      // Assert
      expect(result.info.count, count);
      expect(result.info.pages, pages);
      expect(result.info.next?.toString(), scenario.next);
      expect(result.info.prev?.toString(), scenario.prev);
      expect(result.info.hasNext, scenario.next != null);
      expect(result.info.hasPrevious, scenario.prev != null);
      expect(result.results, ['Rick Sanchez']);
    });
  }

  test('accepts an empty page without invoking the item decoder', () {
    // Arrange
    final json = paginatedJson(count: 0, pages: 0, results: []);

    // Act
    final result = PaginatedResponseMapper.fromJson<int>(
      json,
      decodeItem: (_) => throw StateError('Unexpected decoding'),
    );

    // Assert
    expect(result.results, isEmpty);
    expect(result.info.count, 0);
    expect(result.info.pages, 0);
  });

  final invalidEnvelopes = <Object?>[
    null,
    [],
    {},
    {'info': [], 'results': []},
    {'info': paginatedJson()['info'], 'results': null},
    {
      'info': paginatedJson()['info'],
      'results': [42],
    },
  ];
  for (var i = 0; i < invalidEnvelopes.length; i++) {
    test('rejects malformed envelope $i', () {
      // Arrange
      final json = invalidEnvelopes[i];

      // Act
      Object decode() => PaginatedResponseMapper.fromJson<int>(
        json,
        decodeItem: (item) => item['id'] as int,
      );

      // Assert
      expect(decode, throwsFormatException);
    });
  }

  for (final key in ['count', 'pages', 'next', 'prev']) {
    final invalidValues = key == 'count' || key == 'pages'
        ? <Object?>[null, -1, 1.5, '2']
        : <Object?>[
            42,
            '',
            '/api/character?page=2',
            'ftp://example.test/file',
            'https://',
          ];
    for (final value in invalidValues) {
      test('rejects invalid $key value $value', () {
        // Arrange
        final json = Map<String, dynamic>.from(paginatedJson()['info'] as Map);
        json[key] = value;

        // Act
        PaginationInfo decode() => PaginationInfoMapper.fromJson(json);

        // Assert
        expect(decode, throwsFormatException);
      });
    }
    test('rejects missing $key', () {
      // Arrange
      final json = Map<String, dynamic>.from(paginatedJson()['info'] as Map);
      json.remove(key);

      // Act
      PaginationInfo decode() => PaginationInfoMapper.fromJson(json);

      // Assert
      expect(decode, throwsFormatException);
    });
  }

  test('preserves item decoder failures', () {
    // Arrange
    final failure = FormatException('Invalid resource');
    final json = paginatedJson();

    // Act
    Object decode() => PaginatedResponseMapper.fromJson<int>(
      json,
      decodeItem: (_) => throw failure,
    );

    // Assert
    expect(decode, throwsA(same(failure)));
  });
}
