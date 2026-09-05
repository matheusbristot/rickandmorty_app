import '../../domain/entities/paginated_response.dart';
import '../mappers/json_item_decoder.dart';

abstract interface class PaginatedClient {
  /// Fetches a path relative to the NetworkClient base URL.
  ///
  /// Page zero is normalized to one. Negative pages are rejected before I/O.
  /// An explicit page replaces any page in [path]; other query values survive.
  Future<PaginatedResponse<T>> getPage<T>(
    String path, {
    int page = 1,
    required JsonItemDecoder<T> decodeItem,
  });

  /// Fetches an absolute HTTP(S) URL, including a returned next/prev link.
  ///
  /// The URL is used unchanged. Callers decide whether to follow nullable links.
  /// Network and item decoder failures propagate to the consuming data layer.
  Future<PaginatedResponse<T>> getPageUri<T>(
    Uri uri, {
    required JsonItemDecoder<T> decodeItem,
  });
}
