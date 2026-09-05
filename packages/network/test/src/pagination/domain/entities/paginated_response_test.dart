import 'package:network/network_entities.dart';
import 'package:test/test.dart';

void main() {
  test('copies results and prevents mutations', () {
    // Arrange
    final source = [1];
    const info = PaginationInfo(count: 1, pages: 1, next: null, prev: null);

    // Act
    final result = PaginatedResponse(info: info, results: source);
    source.add(2);

    // Assert
    expect(result.results, [1]);
    expect(() => result.results.add(3), throwsUnsupportedError);
  });
}
