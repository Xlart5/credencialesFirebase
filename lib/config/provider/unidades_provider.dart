import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constans/constants/environment.dart';
import '../models/unidad_model.dart';

// Funciones "Trabajadoras" (Fuera de la clase para el compute)
List<UnidadModel> parseUnidades(String jsonStr) {
  final List<dynamic> unData = json.decode(jsonStr);
  return unData.map((e) => UnidadModel.fromJson(e)).toList();
}

List<CargoUnidadModel> parseCargos(String jsonStr) {
  final List<dynamic> carData = json.decode(jsonStr);
  return carData.map((e) => CargoUnidadModel.fromJson(e)).toList();
}

class UnidadesProvider extends ChangeNotifier {
  final String _baseUrl = Environment.apiUrl;

  List<UnidadModel> _unidades = [];
  List<CargoUnidadModel> _todosLosCargos = [];
  bool _isLoading = false;

  List<UnidadModel> get unidades => _unidades;
  bool get isLoading => _isLoading;

  List<CargoUnidadModel> getCargosPorUnidad(int unidadId) {
    return _todosLosCargos.where((c) => c.unidadId == unidadId).toList();
  }

  // =====================================
  // 1. LEER (READ) - CARGAR CON CACHÉ
  // =====================================
  Future<void> fetchDatosUnidades() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUnidades = prefs.getString('unidades_cache');
    final cachedCargos = prefs.getString('cargos_cache');

    // 1. CARGAMOS DEL DISCO DURO AL INSTANTE
    if (cachedUnidades != null && cachedCargos != null) {
      _unidades = await compute(parseUnidades, cachedUnidades);
      _todosLosCargos = await compute(parseCargos, cachedCargos);
      _isLoading = false;
      notifyListeners();
    } else {
      _isLoading = true;
      notifyListeners();
    }

    // 2. BUSCAMOS EN INTERNET EN MODO FANTASMA
    try {
      final resUnidades = await http.get(
        Uri.parse('$_baseUrl/api/unidades'),
        headers: Environment.authHeaders,
      );
      final resCargos = await http.get(
        Uri.parse('$_baseUrl/api/cargos-proceso'),
        headers: Environment.authHeaders,
      );

      if (resUnidades.statusCode == 200 && resCargos.statusCode == 200) {
        final stringUnidades = utf8.decode(resUnidades.bodyBytes);
        final stringCargos = utf8.decode(resCargos.bodyBytes);

        await prefs.setString('unidades_cache', stringUnidades);
        await prefs.setString('cargos_cache', stringCargos);

        _unidades = await compute(parseUnidades, stringUnidades);
        _todosLosCargos = await compute(parseCargos, stringCargos);

        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error cargando gestión de unidades: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // =====================================
  // 2. CREAR (CREATE)
  // =====================================
  Future<bool> addUnidad(String nombre, String abreviatura) async {
    try {
      final url = Uri.parse('$_baseUrl/api/unidades');
      final response = await http.post(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          'nombre': nombre.toUpperCase(),
          'abreviatura': abreviatura.toUpperCase(),
          'estado': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDatosUnidades(); // Refrescamos la lista
        return true;
      }
      return false;
    } catch (e) {
      print("Error al crear unidad HTTP: $e");
      return false;
    }
  }

  Future<bool> addCargo(String nombre, int unidadId, String tipo) async {
    try {
      final url = Uri.parse('$_baseUrl/api/cargos-proceso');
      final response = await http.post(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          'nombre': nombre.toUpperCase(),
          'unidadId': unidadId,
          'tipo': tipo.toUpperCase(),
          'activo': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDatosUnidades(); // Refrescamos
        return true;
      }
      return false;
    } catch (e) {
      print("Error al crear cargo HTTP: $e");
      return false;
    }
  }

  // =====================================
  // 3. ACTUALIZAR (UPDATE)
  // =====================================
  Future<bool> updateUnidad(
    int id,
    String nuevoNombre,
    String nuevaAbreviatura,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/api/unidades/$id');
      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          'nombre': nuevoNombre.toUpperCase(),
          'abreviatura': nuevaAbreviatura.toUpperCase(),
          'estado': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDatosUnidades(); // Refrescamos
        return true;
      }
      return false;
    } catch (e) {
      print("Error al actualizar unidad HTTP: $e");
      return false;
    }
  }

  Future<bool> updateCargo(int id, int unidadId, String nuevoNombre) async {
    try {
      final url = Uri.parse('$_baseUrl/api/cargos-proceso/$id');
      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          'nombre': nuevoNombre.toUpperCase(),
          'unidadId': unidadId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDatosUnidades();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // =====================================
  // 4. ELIMINAR (DELETE FÍSICO)
  // =====================================
  Future<bool> deleteUnidad(int id) async {
    try {
      final url = Uri.parse('$_baseUrl/api/unidades/$id');
      final response = await http.delete(url, headers: Environment.authHeaders);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchDatosUnidades();
        return true;
      }
      return false;
    } catch (e) {
      print("Error al eliminar unidad HTTP: $e");
      return false;
    }
  }

  Future<bool> deleteCargo(int id, int unidadId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/cargos-proceso/$id');
      final response = await http.delete(url, headers: Environment.authHeaders);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchDatosUnidades();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
