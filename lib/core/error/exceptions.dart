class ServerException implements Exception {
  String? message;

  ServerException({this.message});
}

class ValidationException {
  final String? message;
  ValidationException({this.message});
}

class CacheException implements Exception {}
