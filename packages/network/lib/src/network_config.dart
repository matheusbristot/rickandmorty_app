class NetworkConfig {
  const NetworkConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 2,
    this.retryBaseDelay = const Duration(milliseconds: 500),
    this.maxRetryDelay = const Duration(seconds: 5),
  });

  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final Duration retryBaseDelay;
  final Duration maxRetryDelay;
}
