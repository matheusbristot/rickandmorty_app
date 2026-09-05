import '../../domain/entities/pagination_info.dart';

/// Pure conversion from the API metadata to an entity.
final class PaginationInfoMapper {
  PaginationInfoMapper._();

  static PaginationInfo fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      count: _nonNegativeInt(json['count']),
      pages: _nonNegativeInt(json['pages']),
      next: _link(json, 'next'),
      prev: _link(json, 'prev'),
    );
  }

  static int _nonNegativeInt(Object? value) {
    if (value is! int || value < 0) {
      throw const FormatException('Invalid pagination count or pages.');
    }
    return value;
  }

  static Uri? _link(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key)) {
      throw FormatException('Missing pagination link: $key.');
    }
    final value = json[key];
    if (value == null) return null;
    final uri = value is String ? Uri.tryParse(value) : null;
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw FormatException('Invalid pagination link: $key.');
    }
    return uri;
  }
}
