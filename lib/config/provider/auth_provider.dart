import 'dart:convert';
import 'package:carnetizacion/config/constans/constants/environment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

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
        headers: Environment.authHeaders,
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        _currentUser = UserModel.fromJson(decodedData);
        Environment.token = _currentUser!.token;

        final prefs = await SharedPreferences.getInstance();

        // 🔥 NUEVA LÓGICA RBAC SÚPER SIMPLE: Guardamos Rol y Nombre de Unidad
        String userRol = decodedData['rol']?.toString().toUpperCase() ?? '';
        String nombreUnidad = decodedData['descripcion']?.toString() ?? ''; // La descripción es la Unidad
        
        await prefs.setString('rol', userRol);
        await prefs.setString('nombreUnidad', nombreUnidad);

        if (recordar) {
          await prefs.setString('jwt_token', _currentUser!.token);
          await prefs.setString('user_data', jsonEncode(decodedData));
        }

        _isLoading = false;
        notifyListeners();
        return true; 
      } else {
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

  Future<void> logout() async {
    _currentUser = null;
    Environment.token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
    await prefs.remove('rol');           // Limpiar rol
    await prefs.remove('nombreUnidad');  // Limpiar unidad
    await prefs.remove('personal_cache');

    notifyListeners();
  }

  void restaurarSesion(String token, String userDataJson) async {
    Environment.token = token; 
    final decodedData = json.decode(userDataJson);
    _currentUser = UserModel.fromJson(decodedData);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rol', decodedData['rol']?.toString().toUpperCase() ?? '');
    await prefs.setString('nombreUnidad', decodedData['descripcion']?.toString() ?? '');

    notifyListeners();
  }
}