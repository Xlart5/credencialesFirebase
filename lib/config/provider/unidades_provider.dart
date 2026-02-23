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
  // CARGAR CON CACHÉ (Velocidad Luz)
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
      final resUnidades = await http.get(Uri.parse('$_baseUrl/api/unidades'), headers: {'Accept': 'application/json'});
      final resCargos = await http.get(Uri.parse('$_baseUrl/api/cargos-proceso'), headers: {'Accept': 'application/json'});

      if (resUnidades.statusCode == 200 && resCargos.statusCode == 200) {
        final stringUnidades = utf8.decode(resUnidades.bodyBytes);
        final stringCargos = utf8.decode(resCargos.bodyBytes);

        // Guardamos en disco para la próxima vez
        await prefs.setString('unidades_cache', stringUnidades);
        await prefs.setString('cargos_cache', stringCargos);

        // Procesamos
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
}