import '../../../network_client.dart';
import '../mappers/paginated_response_mapper.dart';
import 'paginated_client.dart';
import '../../domain/entities/paginated_response.dart';
import '../mappers/json_item_decoder.dart';

/// Stateless pagination adapter. The owner retains the client's lifecycle.
final class PaginatedClientImpl implements PaginatedClient {
  PaginatedClientImpl(this._client);

  final NetworkClient _client;

  @override
  Future<PaginatedResponse<T>> getPage<T>(
    String path, {
    int page = 1,
    required JsonItemDecoder<T> decodeItem,
  }) async {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final uri = Uri.parse(path);
    if (uri.hasScheme || uri.hasAuthority || uri.hasFragment) {
      throw ArgumentError.value(path, 'path', 'Expected a relative API path.');
    }
    final pagedUri = uri.replace(
      queryParameters: {
        ...uri.queryParametersAll,
        'page': ['${page == 0 ? 1 : page}'],
      },
    );
    final json = await _client.getJson(pagedUri.toString());
    return PaginatedResponseMapper.fromJson<T>(json, decodeItem: decodeItem);
  }

  @override
  Future<PaginatedResponse<T>> getPageUri<T>(
    Uri uri, {
    required JsonItemDecoder<T> decodeItem,
  }) async {
    if (!uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(
        uri,
        'uri',
        'Expected an absolute HTTP(S) URL.',
      );
    }
    final json = await _client.getJsonUri(uri);
    return PaginatedResponseMapper.fromJson<T>(json, decodeItem: decodeItem);
  }
}
