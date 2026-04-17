import 'dart:convert';
import 'package:carnetizacion/config/constans/constants/environment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  String? _selectedCargoFilter;
  String? get selectedCargoFilter => _selectedCargoFilter;

  // 🔥 NUEVO: Estado del filtro impreso
  bool? _filtroImpreso;
  bool? get filtroImpreso => _filtroImpreso;

  final Set<int> _contratosCerradosVisualmente = {};
  final Set<Employee> _selectedForPrint = {};
  Set<Employee> get selectedForPrint => _selectedForPrint;

  final Set<String> _unidadesDisponibles = {};
  final Set<String> _estadosDisponibles = {};
  final Map<String, List<String>> _cargosPorUnidad = {};

  List<Employee> get allEmployees => _allEmployees;
  String get searchQuery => _searchQuery;
  List<Employee> get employees => _filteredEmployees;
  bool get isLoading => _isLoading;
  Set<String> get unidadesDisponibles => _unidadesDisponibles;
  Set<String> get estadosDisponibles => _estadosDisponibles;
  Map<String, List<String>> get cargosPorUnidad => _cargosPorUnidad;
  
  String? get selectedUnidadFilter => _selectedUnidadFilter;
  String? get selectedEstadoFilter => _selectedEstadoFilter;

  final Set<Employee> _selectedForCertificados = {};
  Set<Employee> get selectedForCertificados => _selectedForCertificados;

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
  int get totalActivos => _allEmployees.where((e) => e.colorEstado == Colors.green).length;
  int get totalPendientes => _allEmployees.where((e) => e.estadoActual.toUpperCase() == "PERSONAL REGISTRADO").length;
  int get printedCredentials => _allEmployees.where((e) => e.estadoActual.toUpperCase() == "CREDENCIAL IMPRESO").length;
  int get pendingRequests => _allEmployees.where((e) => e.estadoActual.toUpperCase() == "PERSONAL REGISTRADO").length;
  List<Employee> get pendingPrintingEmployees => _allEmployees.where((e) => e.estadoActual.toUpperCase() == "PERSONAL REGISTRADO").toList();

  Future<List<Employee>> _filtrarPorRol(String jsonString) async {
    List<Employee> todos = await compute(parseEmployeesInBackground, jsonString);

    final prefs = await SharedPreferences.getInstance();
    String rol = prefs.getString('rol') ?? '';
    
    if (rol != 'CONSULTA') return todos;

    String miUnidad = prefs.getString('nombreUnidad') ?? '';
    
    if (miUnidad.isEmpty) {
      print("❌ El usuario es CONSULTA pero no tiene Unidad asignada en el Login.");
      return [];
    }

    print("🛑 Filtrando usuarios que pertenezcan a la unidad: '$miUnidad'");
    
    return todos.where((emp) => 
      emp.unidad.trim().toLowerCase() == miUnidad.trim().toLowerCase()
    ).toList();
  }

  Future<void> fetchEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedJson = prefs.getString('personal_cache');

    if (cachedJson != null && cachedJson.isNotEmpty) {
      _allEmployees = await _filtrarPorRol(cachedJson);
      _actualizarListasSecundarias();
      _isLoading = false;
      notifyListeners();
    } else {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final url = Uri.parse('$_baseUrl/api/personal/detalles');
      final response = await http.get(url, headers: Environment.authHeaders);

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        await prefs.setString('personal_cache', jsonString);

        _allEmployees = await _filtrarPorRol(jsonString);

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

  Future<void> fetchPersonalParaMasivo() async {
    try {
      final url = Uri.parse('$_baseUrl/api/personal/detalles/sindiscrimiar');
      final response = await http.get(url, headers: Environment.authHeaders);

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        _empleadosMasivo = await _filtrarPorRol(jsonString);
        notifyListeners();
      }
    } catch (e) {
      print('Error Fetch Masivo: $e');
    }
  }

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

  void _actualizarListasSecundarias() async {
    _unidadesDisponibles.clear();
    _estadosDisponibles.clear();
    _cargosPorUnidad.clear();

    for (var emp in _allEmployees) {
      if (emp.unidad.isNotEmpty) {
        _unidadesDisponibles.add(emp.unidad);
        if (emp.cargo.isNotEmpty) {
          if (!_cargosPorUnidad.containsKey(emp.unidad)) {
            _cargosPorUnidad[emp.unidad] = [];
          }
          if (!_cargosPorUnidad[emp.unidad]!.contains(emp.cargo)) {
            _cargosPorUnidad[emp.unidad]!.add(emp.cargo);
          }
        }
      }
      if (emp.estadoActual.isNotEmpty) _estadosDisponibles.add(emp.estadoActual);
    }
    
    _cargosPorUnidad.forEach((key, value) => value.sort());
    
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('rol') == 'CONSULTA' && _unidadesDisponibles.isNotEmpty) {
      _selectedUnidadFilter = _unidadesDisponibles.first;
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
      bool matchesUnidad = _selectedUnidadFilter == null || emp.unidad == _selectedUnidadFilter;
      bool matchesEstado = _selectedEstadoFilter == null || emp.estadoActual == _selectedEstadoFilter;
      bool matchesCargo = _selectedCargoFilter == null || emp.cargo == _selectedCargoFilter;

      return matchesSearch && matchesUnidad && matchesEstado && matchesCargo;
    }).toList();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setUnidadYCargo(String? unidad, String? cargo) {
    _selectedUnidadFilter = unidad;
    _selectedCargoFilter = cargo;
    _applyFilters();
  }

  void toggleUnidadFilter(String unidad) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('rol') == 'CONSULTA') return; 

    _selectedUnidadFilter = _selectedUnidadFilter == unidad ? null : unidad;
    _selectedCargoFilter = null; 
    _applyFilters();
  }

  void toggleEstadoFilter(String estado) {
    _selectedEstadoFilter = _selectedEstadoFilter == estado ? null : estado;
    _applyFilters();
  }

  // 🔥 NUEVO: SETTER PARA EL FILTRO IMPRESO
  void setFiltroImpreso(bool? valor) {
    _filtroImpreso = valor;
    notifyListeners();
  }

  void clearFilters() async {
    final prefs = await SharedPreferences.getInstance();
    _searchQuery = '';
    _selectedCargoFilter = null;
    _selectedEstadoFilter = null;
    _filtroImpreso = null; // 🔥 LIMPIAR ESTE TAMBIÉN

    if (prefs.getString('rol') != 'CONSULTA') {
      _selectedUnidadFilter = null;
    }
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

  Future<bool> markAsPrinted(Employee emp) async {
    try {
      final url = Uri.parse('$_baseUrl/api/estados-personal/${emp.id}/imprimir-credencial');
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
    if (empleados.isEmpty) return false;
    try {
      final url = Uri.parse('$_baseUrl/api/estados-personal/entregar-credencial/masivo');
      final List<int> personalIds = empleados.map((emp) => emp.id).toList();
      final response = await http.put(url, headers: Environment.authHeaders, body: jsonEncode({"personalIds": personalIds, "observacion": "Habilitación masiva desde panel de administración"}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        for (var emp in empleados) {
          updateEmployeeLocal(emp.copyWith(estadoActual: "PERSONAL ACTIVO"));
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error al hacer petición masiva: $e');
      return false;
    }
  }

  Future<bool> marcarCredencialDevueltaMasivo(List<Employee> empleados) async {
    if (empleados.isEmpty) return false;
    try {
      final url = Uri.parse('$_baseUrl/api/estados-personal/devolver-credencial/masivo');
      final List<int> personalIds = empleados.map((emp) => emp.id).toList();
      final response = await http.put(url, headers: Environment.authHeaders, body: jsonEncode({"personalIds": personalIds, "observacion": "Devolución masiva de credenciales desde el sistema"}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        for (var emp in empleados) {
          updateEmployeeLocal(emp.copyWith(estadoActual: "CREDENCIAL DEVUELTO"));
        }
        return true;
      } else {
        print("❌ Error backend masivo: Código ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print('❌ Error al procesar devolución masiva: $e');
      return false;
    }
  }

  void setEmpleadosHistoricosTemporales(List<Employee> historicos) {
    _unidadesDisponibles.clear();
    _cargosPorUnidad.clear();

    for (var emp in historicos) {
      if (emp.unidad.isNotEmpty) {
        _unidadesDisponibles.add(emp.unidad);
        if (emp.cargo.isNotEmpty) {
          if (!_cargosPorUnidad.containsKey(emp.unidad)) {
            _cargosPorUnidad[emp.unidad] = [];
          }
          if (!_cargosPorUnidad[emp.unidad]!.contains(emp.cargo)) {
            _cargosPorUnidad[emp.unidad]!.add(emp.cargo);
          }
        }
      }
    }
    
    _cargosPorUnidad.forEach((key, value) => value.sort());
  }

  Future<bool> registrarFechasProceso(int personalId, DateTime fechaInicio, DateTime fechaFin) async {
    try {
      final url = Uri.parse('$_baseUrl/api/historiales-cargo-proceso/personal/$personalId/historial-activo');
      final response = await http.put(url, headers: Environment.authHeaders, body: jsonEncode({"fechaInicio": fechaInicio.toUtc().toIso8601String(), "fechaFin": fechaFin.toUtc().toIso8601String(), "activo": false}));
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        _contratosCerradosVisualmente.add(personalId);
        final index = _allEmployees.indexWhere((e) => e.id == personalId);
        if (index != -1) {
          updateEmployeeLocal(_allEmployees[index].copyWith(estadoActual: "CONTRATO TERMINADO"));
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
      final String fechaSegura = DateTime.now().subtract(const Duration(minutes: 2)).toUtc().toIso8601String();
      final payload = {"cargoProcesoId": nuevoCargoId, "personalId": emp.id, "fechaInicio": fechaSegura, "activo": true};
      final response = await http.post(url, headers: Environment.authHeaders, body: jsonEncode(payload));
      if (response.statusCode == 200 || response.statusCode == 201) {
        _contratosCerradosVisualmente.remove(emp.id);
        await reiniciarEstadoRegistrado(emp.id);
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
      final url = Uri.parse('$_baseUrl/api/estados-personal/$personalId/estado-registrado');
      final response = await http.put(url, headers: Environment.authHeaders);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final index = _allEmployees.indexWhere((e) => e.id == personalId);
        if (index != -1) {
          updateEmployeeLocal(_allEmployees[index].copyWith(estadoActual: "PERSONAL REGISTRADO"));
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEmployee(int empleadoId, Map<String, dynamic> newData) async {
    try {
      final url = Uri.parse('$_baseUrl/api/personal/$empleadoId/admin');
      final response = await http.put(url, headers: Environment.authHeaders, body: jsonEncode({"nombre": newData['nombre'], "apellidoPaterno": newData['apellidoPaterno'], "apellidoMaterno": newData['apellidoMaterno'], "carnetIdentidad": newData['ci'], "correo": newData['correo'], "celular": newData['celular'], "accesoComputo": newData['accesoComputo'], "nroCircunscripcion": newData['circunscripcion'], "cargoID": newData['cargoID'], "tipo": newData['tipo'], "imagenId": newData['imagenId']}));
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
      final response = await http.get(Uri.parse('$_baseUrl/api/personal/por/circunscripcion/$cir'), headers: Environment.authHeaders);
      if (response.statusCode == 200) _reportData = json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {} finally {
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
      final url = Uri.parse('$_baseUrl/api/historiales-cargo-proceso/personal/$personalId');
      final response = await http.get(url, headers: Environment.authHeaders);
      if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> fetchPersonalActivo() async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = Uri.parse('$_baseUrl/api/personal/detalles');
      final response = await http.get(url, headers: Environment.authHeaders);
      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        _allEmployees = await _filtrarPorRol(jsonString);
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

  Future<bool> cambiarAccesoComputo(int personalId, bool tieneAcceso) async {
    try {
      final url = Uri.parse('$_baseUrl/api/personal/$personalId/acceso');
      final response = await http.put(url, headers: Environment.authHeaders, body: jsonEncode({"accesoComputo": tieneAcceso}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final index = _allEmployees.indexWhere((e) => e.id == personalId);
        if (index != -1) {
          updateEmployeeLocal(_allEmployees[index].copyWith(accesoComputo: tieneAcceso));
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
      final url = Uri.parse('$_baseUrl/api/personal/accesoMasivo');
      final response = await http.put(url, headers: Environment.authHeaders, body: jsonEncode({"personalIds": personalIds, "observacion": "Habilitación masiva desde panel de Cómputo"}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        for (var id in personalIds) {
          final index = _allEmployees.indexWhere((e) => e.id == id);
          if (index != -1) {
            _allEmployees[index] = _allEmployees[index].copyWith(accesoComputo: true);
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

  Future<bool> actualizarImagenPerfil(int personalId, int imagenId, XFile nuevaImagen) async {
    try {
      final url = Uri.parse('$_baseUrl/api/personal/admin/$personalId/imagen/$imagenId');
      var request = http.MultipartRequest('PUT', url);
      request.headers.addAll(Environment.authHeaders);
      final fileBytes = await nuevaImagen.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: 'foto_perfil_${personalId}.jpg'));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchEmployees();
        return true;
      }
      return false;
    } catch (e) {
      print("Error subiendo foto: $e");
      return false;
    }
  }

  Future<bool> cerrarContratosMasivoPorCargo({required int cargoProcesoId, required DateTime fechaInicio, required DateTime fechaFin}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/historiales-cargo-proceso/actualizar-fechas');
      final payload = {"procesoElectoralId": 1, "cargoProcesoId": cargoProcesoId, "fechaInicio": fechaInicio.toUtc().toIso8601String(), "fechaFin": fechaFin.toUtc().toIso8601String(), "activo": false};
      final response = await http.post(url, headers: Environment.authHeaders, body: jsonEncode(payload));
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        await fetchPersonalActivo(); 
        return true;
      } else {
        print("❌ Error Backend: Código ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Excepción en cierre masivo: $e");
      return false;
    }
  }

  Future<bool> finalizarContratoEnFirebase({required Employee emp, required DateTime fechaInicio, required DateTime fechaFin, required String cargoDescripcion, required String tipoContrato}) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final String docId = emp.id.toString();
      await firestore.collection('personal_historico').doc(docId).set({'idBackend': emp.id, 'nombreCompleto': emp.nombreCompleto, 'ci': emp.ci, 'ultimaUnidad': emp.unidad, 'ultimoCargo': emp.cargo, 'fechaRegistroFirebase': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      await firestore.collection('personal_historico').doc(docId).collection('contratos_cerrados').add({'cargo': emp.cargo, 'unidad': emp.unidad, 'fechaInicio': fechaInicio.toIso8601String(), 'fechaFin': fechaFin.toIso8601String(), 'cargoDescripcion': cargoDescripcion, 'tipoContrato': tipoContrato, 'impreso': false, 'fechaRegistro': FieldValue.serverTimestamp()});
      return true;
    } catch (e) {
      print("❌ Error Firebase: $e");
      return false;
    }
  }

  // 🔥 ACTUALIZADO: Leemos el campo "impreso" desde la subcolección
// =========================================================================
  // 🔥 MÓDULO FIREBASE: LEER PERSONAS (CORREGIDO PARA CARGA INSTANTÁNEA)
  // =========================================================================
  Future<List<Map<String, dynamic>>> obtenerPersonasHistoricasFirebase() async {
    try {
      // 1 SOLA PETICIÓN PARA TRAER A TODOS
      final snapshot = await FirebaseFirestore.instance.collection('personal_historico').get();
      
      return snapshot.docs.map((doc) {
        var data = doc.data();
        
        // Leemos el booleano directamente del padre. Si no existe (datos viejos), es false.
        // Nos ahorramos miles de peticiones a las subcolecciones.
        data['impreso'] = data['impreso'] ?? false; 
        
        return data;
      }).toList();
    } catch (e) {
      print("Error leyendo personas de Firebase: $e");
      return [];
    }
  }

  // =========================================================================
  // 🔥 MÓDULO FIREBASE: CAMBIAR A IMPRESO = TRUE (EN PADRE E HIJO)
  // =========================================================================
  Future<bool> actualizarEstadoImpresoFirebase(List<int> ids, bool valor) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (var id in ids) {
        final docRef = firestore.collection('personal_historico').doc(id.toString());
        
        // 1. Actualizamos el padre usando merge para no borrar nada (Carga rápida futura)
        batch.set(docRef, {'impreso': valor}, SetOptions(merge: true));

        // 2. Actualizamos la subcolección para mantener la integridad de tu base de datos
        final contratosSnap = await docRef.collection('contratos_cerrados').get();
        for (var cDoc in contratosSnap.docs) {
          batch.update(cDoc.reference, {'impreso': valor});
        }
      }

      await batch.commit();
      return true;
    } catch (e) {
      print("❌ Error al actualizar campo impreso en Firebase: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerContratosDePersonaFirebase(String personalIdBackend) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('personal_historico').doc(personalIdBackend).collection('contratos_cerrados').orderBy('fechaRegistro', descending: true).get();
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['idFirebase'] = doc.id; 
        return data;
      }).toList();
    } catch (e) {
      print("Error leyendo contratos de Firebase: $e");
      return [];
    }
  }

  Future<void> migrarEventualesAFirebase() async {
    print("⏳ Iniciando migración desde el backend lento...");
    try {
      final url = Uri.parse('$_baseUrl/api/personal/detalles');
      final response = await http.get(url, headers: Environment.authHeaders);
      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final List<dynamic> datosBackend = json.decode(jsonString);
        final firestore = FirebaseFirestore.instance;
        WriteBatch batch = firestore.batch();
        int contador = 0;
        int totalSubidos = 0;
        for (var rawData in datosBackend) {
          String ci = rawData['carnetIdentidad']?.toString() ?? 'SIN_CI_$totalSubidos';
          DocumentReference docRef = firestore.collection('usuarios_eventuales').doc(ci);
          batch.set(docRef, {
            'idBackend': rawData['id'] ?? 0,
            'nombre': rawData['nombre'] ?? '',
            'apellidoPaterno': rawData['apellidoPaterno'] ?? '',
            'apellidoMaterno': rawData['apellidoMaterno'] ?? '',
            'nombreCompleto': "${rawData['nombre'] ?? ''} ${rawData['apellidoPaterno'] ?? ''} ${rawData['apellidoMaterno'] ?? ''}".trim(),
            'carnetIdentidad': ci,
            'correo': rawData['correo'] ?? '',
            'celular': rawData['celular'] ?? '',
            'accesoComputo': rawData['accesoComputo'] ?? false,
            'estadoActual': rawData['estadoActual'] ?? 'DESCONOCIDO',
            'cargo': rawData['cargo'] ?? 'Sin Cargo',
            'unidad': rawData['unidad'] ?? 'Sin Unidad',
            'imagen': rawData['imagen'] ?? '',
            'qr': rawData['qr'] ?? '',
            'nroCircunscripcion': rawData['nroCircunscripcion'] ?? 'Sin Circunscripción',
            'imagenId': rawData['imagenId'] ?? 0,
            'tipo': rawData['tipo'] ?? 'EVENTUAL',
            'ultimaSincronizacion': FieldValue.serverTimestamp(),
            'estaAdentro': false, 
          }, SetOptions(merge: true)); 
          contador++;
          totalSubidos++;
          if (contador >= 450) {
            await batch.commit();
            print("📦 Paquete de 450 registros subido a Firebase...");
            batch = firestore.batch(); 
            contador = 0;
          }
        }
        if (contador > 0) {
          await batch.commit();
        }
        print("✅ ¡MIGRACIÓN EXITOSA! Se subieron/actualizaron $totalSubidos eventuales en Firebase.");
      } else {
        print("❌ Error del servidor backend al intentar migrar: Código ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Ocurrió un error al intentar migrar: $e");
    }
  }
}

List<Employee> parseEmployeesInBackground(String responseBody) {
  final List<dynamic> decoded = json.decode(responseBody);
  return decoded.map((e) => Employee.fromJson(e)).toList();
}