import 'dart:convert';
import 'package:carnetizacion/config/constans/constants/environment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 Importante para guardar en disco
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Si tienes un token en el modelo, el usuario está autenticado
  bool get isAuthenticated =>
      _currentUser != null && _currentUser!.token.isNotEmpty;

  Future<bool> login(String username, String password, bool recordar) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final url = Uri.parse('${Environment.apiUrl}/api/auth/login');

      final Map<String, dynamic> bodyData = {
        "username": username,
        "password": password,
        "recordar": recordar,
      };

      final response = await http.post(
        url,
        headers: Environment
            .authHeaders, // En el login enviará el Content-Type sin problemas
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        _currentUser = UserModel.fromJson(decodedData);

        // 🔥 1. GUARDAMOS EL TOKEN EN LA VARIABLE GLOBAL INMEDIATAMENTE
        Environment.token = _currentUser!.token;

        // 🔥 2. SI MARCÓ "RECORDAR", LO GUARDAMOS EN EL DISCO/NAVEGADOR
        if (recordar) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', _currentUser!.token);

          // (Opcional pero recomendado) Guardar los datos del usuario en un string JSON
          // para poder reconstruir el UserModel si presiona F5 en la web.
          await prefs.setString('user_data', jsonEncode(decodedData));
        }

        _isLoading = false;
        notifyListeners();
        return true; // Login exitoso
      } else {
        // Manejar errores (ej. 401 Unauthorized)
        _errorMessage = 'Usuario o contraseña incorrectos.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión con el servidor.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 🔥 3. LOGOUT MEJORADO (Ahora es asíncrono para borrar datos locales)
  Future<void> logout() async {
    _currentUser = null;

    // Vaciamos la variable global para que ya no mande el token en los headers
    Environment.token = null;

    // Borramos cualquier rastro del token en el almacenamiento local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');

    notifyListeners();
  }

  // 🔥 NUEVO: Método para restaurar la sesión al presionar F5
  void restaurarSesion(String token, String userDataJson) {
    Environment.token = token; // Aseguramos el token global
    final decodedData = json.decode(userDataJson);
    _currentUser = UserModel.fromJson(decodedData);
    notifyListeners();
  }
}
