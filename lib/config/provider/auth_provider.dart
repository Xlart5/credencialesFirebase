import 'dart:convert';
import 'package:carnetizacion/config/constans/constants/environment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Si tienes un token, el usuario está autenticado
  bool get isAuthenticated =>
      _currentUser != null && _currentUser!.token.isNotEmpty;

  Future<bool> login(String username, String password, bool recordar) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // ATENCIÓN: Esta es la URL de tu ngrok.
      // Si reinicias ngrok, debes actualizar esta URL.
      final url = Uri.parse('${Environment.apiUrl}/api/auth/login');

      final Map<String, dynamic> bodyData = {
        "username": username,
        "password": password,
        "recordar": recordar,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        _currentUser = UserModel.fromJson(decodedData);

        // Aquí a futuro podrías guardar el token en SharedPreferences
        // si el usuario marcó "recordar".

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

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
