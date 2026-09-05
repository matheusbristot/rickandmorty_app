import 'pagination_info.dart';

/// Converts a resource object without coupling network to feature models.
typedef JsonItemDecoder<T> = T Function(Map<String, dynamic> json);

final class PaginatedResponse<T> {
  PaginatedResponse({required this.info, required List<T> results})
    : results = List<T>.unmodifiable(results);

  final PaginationInfo info;
  final List<T> results;

  factory PaginatedResponse.fromJson(
    Object? json, {
    required JsonItemDecoder<T> decodeItem,
  }) {
    if (json is! Map<String, dynamic> ||
        json['info'] is! Map<String, dynamic> ||
        json['results'] is! List) {
      throw const FormatException('Invalid paginated response.');
    }
    final info = PaginationInfo.fromJson(json['info'] as Map<String, dynamic>);
    final results = (json['results'] as List).map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid pagination item.');
      }
      return decodeItem(item);
    }).toList();
    return PaginatedResponse(info: info, results: results);
  }
}
