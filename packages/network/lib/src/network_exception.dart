class NetworkException implements Exception {
  const NetworkException({
    required this.message,
    this.statusCode,
    this.retryAfter,
  });

  final String message;
  final int? statusCode;
  final Duration? retryAfter;

  @override
  String toString() => 'NetworkException($statusCode): $message';
}
