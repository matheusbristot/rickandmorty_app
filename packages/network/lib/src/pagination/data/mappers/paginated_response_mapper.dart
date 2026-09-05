import '../../domain/entities/paginated_response.dart';
import 'json_item_decoder.dart';
import 'pagination_info_mapper.dart';

/// Pure conversion from the API envelope to an entity.
final class PaginatedResponseMapper {
  PaginatedResponseMapper._();

  static PaginatedResponse<T> fromJson<T>(
    Object? json, {
    required JsonItemDecoder<T> decodeItem,
  }) {
    if (json is! Map<String, dynamic> ||
        json['info'] is! Map<String, dynamic> ||
        json['results'] is! List) {
      throw const FormatException('Invalid paginated response.');
    }
    final info = PaginationInfoMapper.fromJson(
      json['info'] as Map<String, dynamic>,
    );
    final results = (json['results'] as List).map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid pagination item.');
      }
      return decodeItem(item);
    }).toList();
    return PaginatedResponse(info: info, results: results);
  }
}
