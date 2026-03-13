import 'dart:convert';
import 'package:carnetizacion/config/constans/constants/environment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';
import 'package:flutter/foundation.dart';

class EmployeeProvider extends ChangeNotifier {
  final String _baseUrl = Environment.apiUrl;

  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = false;

  String _searchQuery = '';
  String? _selectedUnidadFilter;
  String? _selectedEstadoFilter;

  final Set<int> _contratosCerradosVisualmente = {};

  final Set<Employee> _selectedForPrint = {};
  Set<Employee> get selectedForPrint => _selectedForPrint;

  final Set<String> _unidadesDisponibles = {};
  final Set<String> _estadosDisponibles = {};
  final Set<String> _cargosDisponibles = {};

  List<Employee> get allEmployees => _allEmployees;
  String get searchQuery => _searchQuery;
  List<Employee> get employees => _filteredEmployees;
  bool get isLoading => _isLoading;
  Set<String> get unidadesDisponibles => _unidadesDisponibles;
  Set<String> get estadosDisponibles => _estadosDisponibles;
  Set<String> get cargosDisponibles => _cargosDisponibles;
  String? get selectedUnidadFilter => _selectedUnidadFilter;
  String? get selectedEstadoFilter => _selectedEstadoFilter;

  final Set<Employee> _selectedForCertificados = {};
  Set<Employee> get selectedForCertificados => _selectedForCertificados;

  // 🔥 1. NUEVA VARIABLE EXCLUSIVA PARA MASIVO (No rompe el Dashboard)
  List<Employee> _empleadosMasivo = [];
  List<Employee> get empleadosMasivo => _empleadosMasivo;

  void toggleCertificadoSelection(Employee emp) {
    if (_selectedForCertificados.contains(emp)) {
      _selectedForCertificados.remove(emp);
    } else {
      _selectedForCertificados.add(emp);
    }
    notifyListeners();
  }

  void clearCertificadoSelection() {
    _selectedForCertificados.clear();
    notifyListeners();
  }

  int get totalEmployees => _allEmployees.length;
  int get totalActivos =>
      _allEmployees.where((e) => e.colorEstado == Colors.green).length;
  int get totalPendientes => _allEmployees
      .where((e) => e.estadoActual.toUpperCase() == "PERSONAL REGISTRADO")
      .length;
  int get printedCredentials => _allEmployees
      .where((e) => e.estadoActual.toUpperCase() == "CREDENCIAL IMPRESO")
      .length;
  int get pendingRequests => _allEmployees
      .where((e) => e.estadoActual.toUpperCase() == "PERSONAL REGISTRADO")
      .length;
  List<Employee> get pendingPrintingEmployees => _allEmployees
      .where((e) => e.estadoActual.toUpperCase() == "PERSONAL REGISTRADO")
      .toList();

  // =====================================
  // FETCH PRINCIPAL: RESTAURADO PARA TODA LA APP
  // =====================================
  Future<void> fetchEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedJson = prefs.getString('personal_cache');

    if (cachedJson != null && cachedJson.isNotEmpty) {
      _allEmployees = await compute(parseEmployeesInBackground, cachedJson);
      _actualizarListasSecundarias();
      _isLoading = false;
      notifyListeners();
    } else {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 🔥 RESTAURADO: Usa /detalles para que el Panel de Administración y Credenciales funcionen perfecto
      final url = Uri.parse('$_baseUrl/api/personal/detalles');
      final response = await http.get(url, headers: Environment.authHeaders);

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        await prefs.setString('personal_cache', jsonString);

        _allEmployees = await compute(parseEmployeesInBackground, jsonString);

        // Limpia a los que ya cerramos visualmente
        _allEmployees = _allEmployees.map((emp) {
          if (_contratosCerradosVisualmente.contains(emp.id)) {
            return emp.copyWith(estadoActual: "CONTRATO TERMINADO");
          }
          return emp;
        }).toList();

        _actualizarListasSecundarias();
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error Conexión Fetch: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // =====================================
  // 🔥 FETCH AISLADO: SOLO PARA IMPRESIÓN MASIVA
  // =====================================
  Future<void> fetchPersonalParaMasivo() async {
    try {
      // Este endpoint carga a todos (activos e inactivos) pero se guarda en una lista aparte
      final url = Uri.parse('$_baseUrl/api/personal/detalles/sindiscrimiar');
      final response = await http.get(url, headers: Environment.authHeaders);

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        _empleadosMasivo = await compute(
          parseEmployeesInBackground,
          jsonString,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error Fetch Masivo: $e');
    }
  }

  // Actualización local rápida
  void updateEmployeeLocal(Employee updatedEmployee) {
    final index = _allEmployees.indexWhere((e) => e.id == updatedEmployee.id);
    if (index != -1) {
      _allEmployees[index] = updatedEmployee;
      _applyFilters();
      _guardarCacheManual();
    }
  }

  Future<void> _guardarCacheManual() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonLocal = jsonEncode(
      _allEmployees.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('personal_cache', jsonLocal);
  }

  void _actualizarListasSecundarias() {
    _unidadesDisponibles.clear();
    _estadosDisponibles.clear();
    _cargosDisponibles.clear();

    for (var emp in _allEmployees) {
      if (emp.unidad.isNotEmpty) _unidadesDisponibles.add(emp.unidad);
      if (emp.estadoActual.isNotEmpty)
        _estadosDisponibles.add(emp.estadoActual);
      if (emp.cargo.isNotEmpty) _cargosDisponibles.add(emp.cargo);
    }
    _applyFilters();
  }

  void _applyFilters() {
    _filteredEmployees = _allEmployees.where((emp) {
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final lowerQuery = _searchQuery.toLowerCase();
        matchesSearch =
            emp.nombreCompleto.toLowerCase().contains(lowerQuery) ||
            emp.carnetIdentidad.contains(_searchQuery);
      }
      bool matchesUnidad =
          _selectedUnidadFilter == null || emp.unidad == _selectedUnidadFilter;
      bool matchesEstado =
          _selectedEstadoFilter == null ||
          emp.estadoActual == _selectedEstadoFilter;

      return matchesSearch && matchesUnidad && matchesEstado;
    }).toList();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void toggleUnidadFilter(String unidad) {
    _selectedUnidadFilter = _selectedUnidadFilter == unidad ? null : unidad;
    _applyFilters();
  }

  void toggleEstadoFilter(String estado) {
    _selectedEstadoFilter = _selectedEstadoFilter == estado ? null : estado;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedUnidadFilter = null;
    _selectedEstadoFilter = null;
    _applyFilters();
  }

  void toggleSelection(Employee emp) {
    if (_selectedForPrint.contains(emp)) {
      _selectedForPrint.remove(emp);
    } else {
      _selectedForPrint.add(emp);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedForPrint.clear();
    notifyListeners();
  }

  // =========================================================================================
  // ACTUALIZACIONES HTTP (INTACTAS)
  // =========================================================================================

  Future<bool> markAsPrinted(Employee emp) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/api/estados-personal/${emp.id}/imprimir-credencial',
      );
      final response = await http.put(url, headers: Environment.authHeaders);
      if (response.statusCode == 200 || response.statusCode == 201) {
        updateEmployeeLocal(emp.copyWith(estadoActual: "CREDENCIAL IMPRESO"));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> marcarComoActivoMasivo(List<Employee> empleados) async {
    bool exitoGeneral = true;
    for (var emp in empleados) {
      try {
        final url = Uri.parse(
          '$_baseUrl/api/estados-personal/${emp.id}/entregar-credencial',
        );
        final response = await http.put(url, headers: Environment.authHeaders);
        if (response.statusCode == 200 || response.statusCode == 201) {
          updateEmployeeLocal(emp.copyWith(estadoActual: "PERSONA ACTIVA"));
        } else {
          exitoGeneral = false;
        }
      } catch (e) {
        exitoGeneral = false;
      }
    }
    return exitoGeneral;
  }

  Future<bool> marcarCredencialDevueltaMasivo(List<Employee> empleados) async {
    bool exitoGeneral = true;
    for (var emp in empleados) {
      try {
        final url = Uri.parse(
          '$_baseUrl/api/estados-personal/${emp.id}/devolver-credencial',
        );
        final response = await http.put(url, headers: Environment.authHeaders);
        if (response.statusCode == 200 || response.statusCode == 201) {
          updateEmployeeLocal(
            emp.copyWith(estadoActual: "CREDENCIAL DEVUELTO"),
          );
        } else {
          exitoGeneral = false;
        }
      } catch (e) {
        exitoGeneral = false;
      }
    }
    return exitoGeneral;
  }

  Future<bool> registrarFechasProceso(
    int personalId,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/api/historiales-cargo-proceso/personal/$personalId/historial-activo',
      );
      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          "fechaInicio": fechaInicio.toUtc().toIso8601String(),
          "fechaFin": fechaFin.toUtc().toIso8601String(),
          "activo": false,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        _contratosCerradosVisualmente.add(personalId);
        final index = _allEmployees.indexWhere((e) => e.id == personalId);
        if (index != -1) {
          updateEmployeeLocal(
            _allEmployees[index].copyWith(estadoActual: "CONTRATO TERMINADO"),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registrarNuevoContrato(Employee emp, int nuevoCargoId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/historiales-cargo-proceso');

      // Usamos la hora exacta actual menos 2 minutos para evitar el error 400
      final String fechaSegura = DateTime.now()
          .subtract(const Duration(minutes: 2))
          .toUtc()
          .toIso8601String();

      final payload = {
        "cargoProcesoId": nuevoCargoId,
        "personalId": emp.id,
        "fechaInicio": fechaSegura,
        "activo": true,
      };

      final response = await http.post(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _contratosCerradosVisualmente.remove(emp.id);

        // 🔥 NUEVO PASO: Cambiamos el estado a "PERSONAL REGISTRADO"
        await reiniciarEstadoRegistrado(emp.id);

        // Actualizamos las listas para que la UI se refresque
        await fetchEmployees();
        await fetchPersonalParaMasivo();

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reiniciarEstadoRegistrado(int personalId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/api/estados-personal/$personalId/estado-registrado',
      );
      final response = await http.put(url, headers: Environment.authHeaders);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final index = _allEmployees.indexWhere((e) => e.id == personalId);
        if (index != -1) {
          updateEmployeeLocal(
            _allEmployees[index].copyWith(estadoActual: "PERSONAL REGISTRADO"),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEmployee(
    int empleadoId,
    Map<String, dynamic> newData,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/api/personal/$empleadoId/admin');
      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          "nombre": newData['nombre'],
          "apellidoPaterno": newData['apellidoPaterno'],
          "apellidoMaterno": newData['apellidoMaterno'],
          "carnetIdentidad": newData['ci'],
          "correo": newData['correo'],
          "celular": newData['celular'],
          "accesoComputo": newData['accesoComputo'],
          "nroCircunscripcion": newData['circunscripcion'],
          "cargoID": newData['cargoID'],
          "tipo": newData['tipo'],
          "imagenId": newData['imagenId'],
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchEmployees();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEmployee(int id) async {
    try {
      final url = Uri.parse('$_baseUrl/api/personal/$id');
      final response = await http.delete(url, headers: Environment.authHeaders);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _allEmployees.removeWhere((emp) => emp.id == id);
        _applyFilters();
        _guardarCacheManual();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  List<dynamic> _reportData = [];
  List<dynamic> get reportData => _reportData;
  int get reportTotal => _reportData.length;

  Future<void> fetchReportePorCircunscripcion(String cir) async {
    _isLoading = true;
    _reportData = [];
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/personal/por/circunscripcion/$cir'),
        headers: Environment.authHeaders,
      );
      if (response.statusCode == 200)
        _reportData = json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limpiarReporte() {
    _reportData = [];
    notifyListeners();
  }

  Future<List<dynamic>> obtenerHistorialPersonal(int personalId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/api/historiales-cargo-proceso/personal/$personalId',
      );
      final response = await http.get(url, headers: Environment.authHeaders);
      if (response.statusCode == 200)
        return json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return [];
    } catch (e) {
      return [];
    }
  }

  // =====================================================================================
  // 🔥 ESTE ES EL ÚNICO MÉTODO NUEVO: Exclusivo para la pantalla de Cierres (Certificados)
  // =====================================================================================
  Future<void> fetchPersonalActivo() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Este endpoint carga solo a los que tienen contrato activo
      final url = Uri.parse('$_baseUrl/api/personal/detalles');
      final response = await http.get(url, headers: Environment.authHeaders);

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);

        // Convertimos los datos del servidor sin afectar la caché de credenciales
        _allEmployees = await compute(parseEmployeesInBackground, jsonString);

        // Aplicamos la memoria visual por si acabamos de cerrar uno en esta sesión
        _allEmployees = _allEmployees.map((emp) {
          if (_contratosCerradosVisualmente.contains(emp.id)) {
            return emp.copyWith(estadoActual: "CONTRATO TERMINADO");
          }
          return emp;
        }).toList();

        _actualizarListasSecundarias();
      }
    } catch (e) {
      print('Error en fetchPersonalActivo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // =========================================================================================
  // 🔥 NUEVOS MÉTODOS PARA ACCESO A CÓMPUTO
  // =========================================================================================

  // =========================================================================================
  // 🔥 MÉTODOS PARA ACCESO A CÓMPUTO (ENDPOINTS ACTUALIZADOS)
  // =========================================================================================

  Future<bool> cambiarAccesoComputo(int personalId, bool tieneAcceso) async {
    try {
      // NUEVA URL: 1 por 1
      final url = Uri.parse('$_baseUrl/api/personal/$personalId/acceso');

      // Como ahora es una sola ruta para dar o quitar acceso, le mandamos el estado deseado en el body
      // *Nota: Si tu backend espera este booleano como parámetro en la URL o con otro nombre en el JSON,
      // solo avísame y lo ajustamos en un segundo.
      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({"accesoComputo": tieneAcceso}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final index = _allEmployees.indexWhere((e) => e.id == personalId);
        if (index != -1) {
          updateEmployeeLocal(
            _allEmployees[index].copyWith(accesoComputo: tieneAcceso),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> habilitarComputoMasivo(List<int> personalIds) async {
    try {
      // NUEVA URL: Masivo
      final url = Uri.parse('$_baseUrl/api/personal/accesoMasivo');

      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          "personalIds": personalIds,
          "observacion": "Habilitación masiva desde panel de Cómputo",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Actualizamos localmente
        for (var id in personalIds) {
          final index = _allEmployees.indexWhere((e) => e.id == id);
          if (index != -1) {
            _allEmployees[index] = _allEmployees[index].copyWith(
              accesoComputo: true,
            );
          }
        }
        _applyFilters();
        _guardarCacheManual();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
} // <--- AQUÍ TERMINA LA CLASE EMPLOYEE PROVIDER

// 👇 ESTA FUNCIÓN DEBE IR AFUERA, AL FINAL DE TODO
List<Employee> parseEmployeesInBackground(String responseBody) {
  final List<dynamic> decoded = json.decode(responseBody);
  return decoded.map((e) => Employee.fromJson(e)).toList();
}
