import 'dart:convert';
import 'package:carnetizacion/config/constans/constants/environment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/selection_models.dart';

class RegisterProvider extends ChangeNotifier {
  // === URL BASE ===
  final String baseUrl = Environment.apiUrl;

  // === CONTROL DE PÁGINAS ===
  int _currentPage = 0;
  int get currentPage => _currentPage;

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  // 🔥 NUEVO: Controlar si es Planta o Eventual
  bool _esPersonalDePlanta = false;
  bool get esPersonalDePlanta => _esPersonalDePlanta;

  void setTipoPersonal(bool esPlanta) {
    _esPersonalDePlanta = esPlanta;
    notifyListeners();
  }

  // === DATOS DEL FORMULARIO ===
  // Paso 1: Foto
  XFile? _imageFile;
  int? _imagenId;
  bool _isUploadingImage = false;

  XFile? get imageFile => _imageFile;
  bool get isUploadingImage => _isUploadingImage;
  bool get hasImage => _imagenId != null;

  // Paso 2: Datos Personales
  String nombre = '';
  String paterno = '';
  String materno = '';
  String ci = '';
  String celular = '';

  // === Paso 3: Unidad y Cargo ===
  List<UnidadItem> _unidades = [];
  List<CargoItem> _todosLosCargos = []; 
  bool isLoadingData = false; 

  UnidadItem? selectedUnidad;
  CargoItem? selectedCargo;
  String? selectedCircunscripcion;

  // Lista estática de Cochabamba
  final List<String> circunscripcionesCbba = [
    'C-02', 'C-20', 'C-21', 'C-22', 'C-23', 
    'C-24', 'C-25', 'C-26', 'C-27', 'C-28',
  ];

  List<UnidadItem> get unidades => _unidades;

  // Getter MÁGICO: Filtra los cargos mostrando solo los que pertenecen a la Unidad seleccionada
  List<CargoItem> get availableCargos {
    if (selectedUnidad == null) return [];
    return _todosLosCargos
        .where((cargo) => cargo.unidadId == selectedUnidad!.id)
        .toList();
  }

  // Getter para saber si eligieron Notario
  bool get isNotarioSelected {
    if (selectedCargo == null) return false;
    return selectedCargo!.nombre.toUpperCase().contains('NOTARIO');
  }

  // =====================================
  // FETCH DESDE LA API
  // =====================================
  Future<void> fetchUnidadesYCargos() async {
    isLoadingData = true;
    notifyListeners();

    try {
      // 1. Obtener Unidades
      final resUnidades = await http.get(Uri.parse('$baseUrl/api/unidades'));
      if (resUnidades.statusCode == 200) {
        final List<dynamic> unData = json.decode(utf8.decode(resUnidades.bodyBytes));
        _unidades = unData.map((e) => UnidadItem.fromJson(e)).toList();
      }

      // 2. Obtener Cargos
      final resCargos = await http.get(Uri.parse('$baseUrl/api/cargos-proceso'));
      if (resCargos.statusCode == 200) {
        final List<dynamic> carData = json.decode(utf8.decode(resCargos.bodyBytes));
        _todosLosCargos = carData.map((e) => CargoItem.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error cargando unidades/cargos: $e");
    }

    isLoadingData = false;
    notifyListeners();
  }

  // Paso 4: Verificación
  String correo = '';
  String codigoVerificacion = '';
  bool _isRequestingCode = false;
  bool _isSubmitting = false;

  bool get isRequestingCode => _isRequestingCode;
  bool get isSubmitting => _isSubmitting;

  // === MÉTODOS DE LA API ===

  Future<bool> uploadImage(XFile file) async {
    _isUploadingImage = true;
    _imageFile = file;
    notifyListeners();

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/imagenes/upload'));

      final bytes = await file.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'foto_perfil.jpg',
        contentType: MediaType('image', 'jpeg'), 
      );

      request.files.add(multipartFile);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(responseData);
        _imagenId = decoded['idImagen'];
        _isUploadingImage = false;
        notifyListeners();
        return true;
      } else {
        print("⚠️ EL SERVIDOR RECHAZÓ LA IMAGEN. Código: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ ERROR AL SUBIR IMAGEN: $e");
    }

    _isUploadingImage = false;
    notifyListeners();
    return false;
  }

  Future<bool> solicitarCodigo() async {
    _isRequestingCode = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/personal/solicitar-codigo'),
        headers: Environment.authHeaders,
        body: jsonEncode({"correo": correo, "carnetIdentidad": ci}),
      );

      if (response.statusCode == 200) {
        _isRequestingCode = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Error al solicitar código: $e");
    }
    _isRequestingCode = false;
    notifyListeners();
    return false;
  }

  // 🔥 AQUÍ ESTÁ EL CAMBIO PRINCIPAL (ENDPOINT DINÁMICO)
  // =====================================
  // REGISTRAR PERSONAL (POST /api/personal/registrar)
  // =====================================
  Future<bool> registrarPersonal() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      // 🔥 CORRECCIÓN: La URL es siempre la misma para ambos casos
      final String urlEndpoint = '$baseUrl/api/personal/registrar';

      // Hacemos la petición
      final response = await http.post(
        Uri.parse(urlEndpoint),
        headers: Environment.authHeaders,
        body: jsonEncode({
          "nombre": nombre,
          "apellidoPaterno": paterno,
          "apellidoMaterno": materno,
          "carnetIdentidad": ci,
          "correo": correo,
          "celular": celular,
          "accesoComputo": false,
          "nroCircunscripcion": isNotarioSelected ? selectedCircunscripcion : "",
          
          // 🔥 AQUÍ SE HACE LA DIFERENCIA: "PLANTA" o "EVENTUAL"
          "tipo": _esPersonalDePlanta ? "PLANTA" : "EVENTUAL",
          
          "cargoID": selectedCargo?.id ?? 1,
          "imagenId": _imagenId,
          "codigoVerificacion": codigoVerificacion,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        print("Error del backend. Status: ${response.statusCode}. Body: ${response.body}");
      }
    } catch (e) {
      print("Error al registrar: $e");
    }
    
    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  // =====================================
  // LIMPIAR FORMULARIO
  // =====================================
  void resetForm() {
    _currentPage = 0;
    _esPersonalDePlanta = false; // 🔥 Resetear esto también
    _imageFile = null;
    _imagenId = null;
    nombre = '';
    paterno = '';
    materno = '';
    ci = '';
    celular = '';
    selectedUnidad = null;
    selectedCargo = null;
    selectedCircunscripcion = null;
    correo = '';
    codigoVerificacion = '';
    _isUploadingImage = false;
    _isRequestingCode = false;
    _isSubmitting = false;
    notifyListeners();
  }
}