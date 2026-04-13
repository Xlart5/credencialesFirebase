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
  
  // 🔥 NUEVO: Filtro específico de Cargo
  String? _selectedCargoFilter;
  String? get selectedCargoFilter => _selectedCargoFilter;

  final Set<int> _contratosCerradosVisualmente = {};

  final Set<Employee> _selectedForPrint = {};
  Set<Employee> get selectedForPrint => _selectedForPrint;

  final Set<String> _unidadesDisponibles = {};
  final Set<String> _estadosDisponibles = {};
  
  // 🔥 NUEVO: Mapa para conectar cada Unidad con sus respectivos Cargos
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
      final url = Uri.parse('$_baseUrl/api/personal/detalles');
      final response = await http.get(url, headers: Environment.authHeaders);

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        await prefs.setString('personal_cache', jsonString);

        _allEmployees = await compute(parseEmployeesInBackground, jsonString);

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
    _cargosPorUnidad.clear();

    for (var emp in _allEmployees) {
      if (emp.unidad.isNotEmpty) {
        _unidadesDisponibles.add(emp.unidad);
        // Construimos el mapa relacional
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
    
    // Ordenar alfabéticamente los cargos para mejor UX
    _cargosPorUnidad.forEach((key, value) => value.sort());
    
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
      
      // 🔥 Validación del nuevo filtro
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

  void toggleUnidadFilter(String unidad) {
    _selectedUnidadFilter = _selectedUnidadFilter == unidad ? null : unidad;
    _selectedCargoFilter = null; // Limpia el cargo si se cambia la unidad manualmente
    _applyFilters();
  }

  void toggleEstadoFilter(String estado) {
    _selectedEstadoFilter = _selectedEstadoFilter == estado ? null : estado;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedUnidadFilter = null;
    _selectedCargoFilter = null;
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

  // =========================================================================
  // 🔥 NUEVO MÉTODO OPTIMIZADO: MARCAR COMO ACTIVO MASIVO
  // Usa el endpoint que recibe el array de IDs en una sola petición HTTP
  // =========================================================================
  Future<bool> marcarComoActivoMasivo(List<Employee> empleados) async {
    if (empleados.isEmpty) return false;

    try {
      final url = Uri.parse('$_baseUrl/api/estados-personal/entregar-credencial/masivo');
      
      // Extraemos solo los IDs de la lista de empleados
      final List<int> personalIds = empleados.map((emp) => emp.id).toList();

      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          "personalIds": personalIds,
          "observacion": "Habilitación masiva desde panel de administración"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Si el servidor responde OK, actualizamos todos localmente para no tener que recargar todo
        for (var emp in empleados) {
          updateEmployeeLocal(emp.copyWith(estadoActual: "PERSONA ACTIVA"));
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

 // =========================================================================
  // 🔥 MÉTODO OPTIMIZADO: DEVOLUCIÓN DE CREDENCIAL MASIVA
  // Usa el endpoint que recibe el array de IDs en una sola petición HTTP
  // =========================================================================
  Future<bool> marcarCredencialDevueltaMasivo(List<Employee> empleados) async {
    if (empleados.isEmpty) return false;

    try {
      final url = Uri.parse('$_baseUrl/api/estados-personal/devolver-credencial/masivo');
      
      // 1. Extraemos solo los IDs de la lista de empleados seleccionados
      final List<int> personalIds = empleados.map((emp) => emp.id).toList();

      // 2. Enviamos un solo paquete al servidor
      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          "personalIds": personalIds,
          "observacion": "Devolución masiva de credenciales desde el sistema"
        }),
      );

      // 3. Validamos la respuesta
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Actualizamos localmente para que la tabla cambie al instante sin recargar la BD
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

  Future<bool> registrarFechasProceso(int personalId, DateTime fechaInicio, DateTime fechaFin) async {
    try {
      final url = Uri.parse('$_baseUrl/api/historiales-cargo-proceso/personal/$personalId/historial-activo');
      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          "fechaInicio": fechaInicio.toUtc().toIso8601String(),
          "fechaFin": fechaFin.toUtc().toIso8601String(),
          "activo": false,
        }),
      );

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

      final payload = {
        "cargoProcesoId": nuevoCargoId,
        "personalId": emp.id,
        "fechaInicio": fechaSegura,
        "activo": true,
      };

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
        _allEmployees = await compute(parseEmployeesInBackground, jsonString);
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
      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({"accesoComputo": tieneAcceso}),
      );
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
      final response = await http.put(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode({
          "personalIds": personalIds,
          "observacion": "Habilitación masiva desde panel de Cómputo",
        }),
      );
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
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: 'foto_perfil_${personalId}.jpg',
        ),
      );

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
  // =========================================================================
  // 🔥 CIERRE MASIVO DE CONTRATOS POR CARGO
  // =========================================================================
  // =========================================================================
  // 🔥 CIERRE MASIVO DE CONTRATOS POR CARGO (ACTUALIZADO CON "ACTIVO")
  // =========================================================================
  Future<bool> cerrarContratosMasivoPorCargo({
    required int cargoProcesoId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/historiales-cargo-proceso/actualizar-fechas');
      
      final payload = {
        "procesoElectoralId": 1, // Fijo según el requerimiento
        "cargoProcesoId": cargoProcesoId,
        "fechaInicio": fechaInicio.toUtc().toIso8601String(),
        "fechaFin": fechaFin.toUtc().toIso8601String(),
        "activo": false, // 🔥 NUEVO CAMPO AÑADIDO: 'false' para dar de baja el contrato
      };

      final response = await http.post(
        url,
        headers: Environment.authHeaders,
        body: jsonEncode(payload),
      );

      // Agregamos 204 por si el backend responde "No Content" tras una actualización exitosa
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        // Refrescamos los datos para que la tabla se actualice inmediatamente
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

  // =========================================================================
  // 🔥 MÓDULO FIREBASE: GUARDAR CONTRATO FINALIZADO
  // =========================================================================
  // 🔥 DENTRO DE employee_provider.dart

Future<bool> finalizarContratoEnFirebase({
  required Employee emp,
  required DateTime fechaInicio,
  required DateTime fechaFin,
  required String cargoDescripcion, // "Servicios de Consultoria..." o "Servicio de Terceros"
  required String tipoContrato,      // "Administrativo I", "II" o "III"
}) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final String docId = emp.id.toString();

    await firestore.collection('personal_historico').doc(docId).set({
      'idBackend': emp.id,
      'nombreCompleto': emp.nombreCompleto,
      'ci': emp.ci,
      'ultimaUnidad': emp.unidad,
      'ultimoCargo': emp.cargo,
      'fechaRegistroFirebase': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Guardamos en la subcolección con los nuevos campos
    await firestore.collection('personal_historico').doc(docId).collection('contratos_cerrados').add({
      'cargo': emp.cargo,
      'unidad': emp.unidad,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'cargoDescripcion': cargoDescripcion, // 🔥 NUEVO
      'tipoContrato': tipoContrato,           // 🔥 NUEVO
      'impreso': false,
      'fechaRegistro': FieldValue.serverTimestamp(),
    });

    return true;
  } catch (e) {
    print("❌ Error Firebase: $e");
    return false;
  }
}
  // =========================================================================
  // 🔥 MÓDULO FIREBASE: LEER PERSONAS CON HISTORIAL
  // =========================================================================
  
  // A. Obtener la lista de personas que están en el archivo histórico
  Future<List<Map<String, dynamic>>> obtenerPersonasHistoricasFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('personal_historico').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Error leyendo personas de Firebase: $e");
      return [];
    }
  }

  // B. Obtener todos los contratos cerrados de una persona específica
  Future<List<Map<String, dynamic>>> obtenerContratosDePersonaFirebase(String personalIdBackend) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('personal_historico')
          .doc(personalIdBackend)
          .collection('contratos_cerrados')
          .orderBy('fechaRegistro', descending: true) // Los más recientes primero
          .get();

      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['idFirebase'] = doc.id; // Guardamos el ID del documento por si acaso
        return data;
      }).toList();
    } catch (e) {
      print("Error leyendo contratos de Firebase: $e");
      return [];
    }
  }
  // =========================================================================
  // 🔥 MIGRACIÓN DE DATOS A FIREBASE FIRESTORE
  // =========================================================================
  Future<void> migrarEventualesAFirebase() async {
    print("⏳ Iniciando migración desde el backend lento...");

    try {
      // 1. Llamamos a tu endpoint existente
      final url = Uri.parse('$_baseUrl/api/personal/detalles');
      final response = await http.get(url, headers: Environment.authHeaders);

      if (response.statusCode == 200) {
        // 2. Decodificamos la respuesta usando la misma lógica que ya tienes
        final String jsonString = utf8.decode(response.bodyBytes);
        final List<dynamic> datosBackend = json.decode(jsonString);
        
        // Instancia de Firestore
        final firestore = FirebaseFirestore.instance;
        WriteBatch batch = firestore.batch();
        int contador = 0;
        int totalSubidos = 0;

        // 3. Recorremos cada persona recibida
        for (var rawData in datosBackend) {
          
          // Tratamos de obtener el CI, si no hay, generamos un fallback temporal
          String ci = rawData['carnetIdentidad']?.toString() ?? 'SIN_CI_$totalSubidos';
          
          // Referencia al documento en la colección de Firebase (usamos el CI como ID único)
          DocumentReference docRef = firestore.collection('usuarios_eventuales').doc(ci);

          // 4. Mapeamos TODOS los campos tal cual vienen de tu JSON
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
            
            // Campos de control interno de Firebase
            'ultimaSincronizacion': FieldValue.serverTimestamp(),
            'estaAdentro': false, // Lo forzamos a false por ser la primera carga
          }, SetOptions(merge: true)); // merge: true actualiza datos sin borrar cosas extra

          contador++;
          totalSubidos++;

          // 5. Firebase tiene un límite de 500 operaciones por Batch. Cortamos en 450 para estar seguros.
          if (contador >= 450) {
            await batch.commit();
            print("📦 Paquete de 450 registros subido a Firebase...");
            batch = firestore.batch(); // Reiniciamos el lote
            contador = 0;
          }
        }

        // 6. Subimos el remanente (si quedaron menos de 450 en el último lote)
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