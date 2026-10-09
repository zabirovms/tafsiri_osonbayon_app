/// Thrown when the device has no active internet connection.
class NoInternetException implements Exception {
  final String message;
  const NoInternetException([this.message = 'Пайвастшавӣ ба интернет нест']);

  @override
  String toString() => 'NoInternetException: $message';
}

/// Thrown when the server is reachable but returns a 5xx error or times out.
class ServerUnavailableException implements Exception {
  final String message;
  final int? statusCode;
  const ServerUnavailableException({
    this.message = 'Сервер дастрас нест. Лутфан баъдтар кӯшиш кунед',
    this.statusCode,
  });

  @override
  String toString() => 'ServerUnavailableException($statusCode): $message';
}
