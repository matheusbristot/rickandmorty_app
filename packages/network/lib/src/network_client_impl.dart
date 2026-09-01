import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:http/http.dart' as http;

import 'network_client.dart';
import 'network_config.dart';
import 'network_exception.dart';

final class NetworkClientImpl implements NetworkClient {
  NetworkClientImpl({required NetworkConfig config, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client() {
    _config = config;
  }

  late final NetworkConfig _config;
  final http.Client _httpClient;

  @override
  Future<dynamic> getJson(String path) {
    final baseUri = Uri.parse(_config.baseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return getJsonUri(baseUri.resolve(normalizedPath));
  }

  @override
  Future<dynamic> getJsonUri(Uri uri) async {
    var retryCount = 0;

    try {
      while (true) {
        final response = await _httpClient
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(_config.timeout);

        if (response.statusCode == 429 && retryCount < _config.maxRetries) {
          final delay = _retryDelay(response.headers, retryCount);
          retryCount++;
          await Future<void>.delayed(delay);
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw NetworkException(
            message: _messageForStatus(response.statusCode),
            statusCode: response.statusCode,
            retryAfter: _retryAfter(response.headers),
          );
        }

        try {
          final responseBody = response.body;
          return await Isolate.run(() => jsonDecode(responseBody));
        } on FormatException {
          throw const NetworkException(
            message: 'Não foi possível carregar os dados recebidos.',
          );
        }
      }
    } on NetworkException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException(
        message: 'A conexão demorou demais para responder.',
      );
    } catch (_) {
      // A causa original pode conter detalhes de infraestrutura e nunca deve
      // ser reutilizada como texto apresentado ao usuário.
      throw const NetworkException(
        message: 'Não foi possível conectar ao servidor.',
      );
    }
  }

  String _messageForStatus(int statusCode) {
    return 'Falha na requisição HTTP ($statusCode).';
  }

  Duration _retryDelay(Map<String, String> headers, int retryCount) {
    final retryAfter = _retryAfter(headers);
    if (retryAfter != null && retryAfter > _config.maxRetryDelay) {
      return _config.maxRetryDelay;
    }
    if (retryAfter != null && retryAfter > Duration.zero) return retryAfter;

    final exponentialDelay = _config.retryBaseDelay * (1 << retryCount);
    return exponentialDelay > _config.maxRetryDelay
        ? _config.maxRetryDelay
        : exponentialDelay;
  }

  Duration? _retryAfter(Map<String, String> headers) {
    final seconds = int.tryParse(headers['retry-after'] ?? '');
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds);
  }

  @override
  void close() => _httpClient.close();
}
