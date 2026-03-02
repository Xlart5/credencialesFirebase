class Environment {
  // Tu URL base
  static const String apiUrl =
      'http://api.j0o88kckww4cos8cgog80wsw.158.220.117.118.sslip.io';

  // 🔥 Variable viva en memoria (se actualiza al iniciar sesión)
  static String? token;

  // Getter dinámico: Si hay token, lo inyecta; si no, manda headers limpios
  static Map<String, String> get authHeaders {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
