class SessionExpiredException implements Exception {
  final String message;

  SessionExpiredException([this.message = 'La sesión ha expirado']);

  @override
  String toString() => message;
}
