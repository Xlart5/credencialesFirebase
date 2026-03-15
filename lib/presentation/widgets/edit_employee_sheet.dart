import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb

import '../../config/constans/constants/environment.dart';
import '../../config/models/employee_model.dart';
import '../../config/provider/employee_provider.dart';

void showEditEmployeeSheet(BuildContext context, Employee emp) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => EditEmployeeSheet(employee: emp),
  );
}

class EditEmployeeSheet extends StatefulWidget {
  final Employee employee;
  const EditEmployeeSheet({super.key, required this.employee});

  @override
  State<EditEmployeeSheet> createState() => _EditEmployeeSheetState();
}

class _EditEmployeeSheetState extends State<EditEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _paternoCtrl;
  late TextEditingController _maternoCtrl;
  late TextEditingController _ciCtrl;
  late TextEditingController _celularCtrl;

  final String _baseUrl = Environment.apiUrl; 

  List<dynamic> _listaUnidades = [];
  List<dynamic> _listaCargos = [];

  int? _selectedUnidadId;
  int? _selectedCargoId;

  bool _isSaving = false;
  bool _isUploadingPhoto = false; // Estado para la ruedita de carga de la foto
  bool _isLoadingUnidades = true;
  bool _isLoadingCargos = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.employee.nombre);
    _paternoCtrl = TextEditingController(text: widget.employee.apellidoPaterno);
    _maternoCtrl = TextEditingController(text: widget.employee.apellidoMaterno);
    _ciCtrl = TextEditingController(text: widget.employee.ci);
    _celularCtrl = TextEditingController(text: widget.employee.celular);

    _cargarUnidades();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _paternoCtrl.dispose();
    _maternoCtrl.dispose();
    _ciCtrl.dispose();
    _celularCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // LÓGICA DE FOTO (SELECCIÓN Y SUBIDA)
  // ==========================================
  Future<void> _cambiarFotoPerfil() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4), // 3:4 para credenciales
        uiSettings: [
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.page,
          ),
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Foto',
            toolbarColor: const Color(0xFF1E2B5E),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio3x2,
            lockAspectRatio: true,
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        // Mostramos el diálogo de confirmación
        _mostrarConfirmacionFoto(XFile(croppedFile.path));
      }
    }
  }

  void _mostrarConfirmacionFoto(XFile nuevaImagen) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Cambio"),
        content: const Text("¿Está seguro de cambiar la fotografía de perfil de este empleado?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              Navigator.pop(ctx); // Cierra el diálogo
              _subirFotoAlServidor(nuevaImagen); // Ejecuta la subida
            },
            child: const Text("Sí, Cambiar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _subirFotoAlServidor(XFile nuevaImagen) async {
    setState(() => _isUploadingPhoto = true);

    final provider = context.read<EmployeeProvider>();
    final success = await provider.actualizarImagenPerfil(
      widget.employee.id,
      widget.employee.ImageId,
      nuevaImagen,
    );

    if (mounted) {
      setState(() => _isUploadingPhoto = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fotografía actualizada con éxito"),
            backgroundColor: Colors.green,
          ),
        );
        // Cerramos el panel de edición para que vea la foto nueva en la tabla
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al subir la fotografía"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==========================================
  // FUNCIONES HTTP (CASCADA)
  // ==========================================
  Future<void> _cargarUnidades() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/unidades'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;

        if (mounted) {
          setState(() {
            _listaUnidades = data;
            _isLoadingUnidades = false;
          });

          final currentUnidadStr = widget.employee.unidad.trim().toUpperCase();
          for (var u in _listaUnidades) {
            if (u['nombre'].toString().trim().toUpperCase() == currentUnidadStr) {
              _selectedUnidadId = u['id'];
              break;
            }
          }

          if (_selectedUnidadId != null) {
            _cargarCargos(_selectedUnidadId!);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUnidades = false);
    }
  }

  Future<void> _cargarCargos(int unidadId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingCargos = true;
      _listaCargos = []; 
      _selectedCargoId = null; 
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cargos-proceso/unidad/$unidadId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;

        if (mounted) {
          setState(() {
            _listaCargos = data;
            _isLoadingCargos = false;
          });

          final currentCargoStr = widget.employee.cargo.trim().toUpperCase();
          for (var c in _listaCargos) {
            if (c['nombre'].toString().trim().toUpperCase() == currentCargoStr) {
              _selectedCargoId = c['id'];
              break;
            }
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCargos = false);
    }
  }

  // ==========================================
  // GUARDAR CAMBIOS DE TEXTO
  // ==========================================
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnidadId == null || _selectedCargoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seleccione Unidad y Cargo"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final nuevosDatos = {
      "nombre": _nombreCtrl.text.trim(),
      "apellidoPaterno": _paternoCtrl.text.trim(),
      "apellidoMaterno": _maternoCtrl.text.trim(),
      "ci": _ciCtrl.text.trim(),
      "correo": widget.employee.correo ?? "sin.correo@ejemplo.com",
      "celular": _celularCtrl.text.trim(),
      "accesoComputo": widget.employee.accesoComputo,
      "circunscripcion": widget.employee.Circu,
      "tipo": "EVENTUAL",
      "imagenId": widget.employee.ImageId,
      "cargoID": _selectedCargoId,
    };

    final provider = context.read<EmployeeProvider>();
    bool success = await provider.updateEmployee(
      widget.employee.id,
      nuevosDatos,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Datos actualizados correctamente."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al guardar. Revisa la conexión."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: Container(
          width: 600, 
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
              bottom: Radius.circular(25),
            ),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // =====================================
                // HEADER OSCURO 
                // =====================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2B5E),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.manage_accounts,
                        color: Color(0xFFFFD54F),
                        size: 28,
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Editar Personal",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "ACTUALIZACIÓN DE DATOS Y FOTOGRAFÍA",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // =====================================
                // 🔥 NUEVA SECCIÓN DE FOTOGRAFÍA
                // =====================================
                Container(
                  color: Colors.grey.shade50,
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Círculo de la foto actual
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 3),
                            color: Colors.white,
                            image: widget.employee.photoUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(widget.employee.photoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: widget.employee.photoUrl.isEmpty
                              ? Icon(Icons.person, size: 70, color: Colors.grey.shade400)
                              : null,
                        ),

                        // Si está subiendo, tapamos con ruedita
                        if (_isUploadingPhoto)
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.amber),
                            ),
                          ),

                        // Botón flotante para editar
                        if (!_isUploadingPhoto)
                          GestureDetector(
                            onTap: _cambiarFotoPerfil,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: Colors.grey),

                // =====================================
                // FORMULARIO
                // =====================================
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Fila 1: Nombres y Apellidos ---
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(Icons.person, "Nombres"),
                                  _buildTextField("Ej. Juan", _nombreCtrl),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(Icons.person_outline, "Paterno"),
                                  _buildTextField("Ej. Pérez", _paternoCtrl),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(Icons.person_outline, "Materno"),
                                  _buildTextField("Ej. López", _maternoCtrl),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- Fila 2: CI y Celular ---
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(
                                    Icons.badge,
                                    "Cédula de Identidad",
                                  ),
                                  _buildTextField("Ej. 1234567", _ciCtrl),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(Icons.phone, "Nro. Celular"),
                                  _buildTextField("Ej. 70000000", _celularCtrl),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        const Divider(),
                        const SizedBox(height: 20),

                        // --- Fila 3: ASIGNACIÓN ---
                        _buildLabel(Icons.business, "Unidad / Departamento *"),
                        _isLoadingUnidades
                            ? const LinearProgressIndicator(
                                color: Color(0xFFFFD54F),
                              )
                            : DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: _selectedUnidadId,
                                decoration: _inputDecoration(
                                  "Seleccione una Unidad",
                                ),
                                items: _listaUnidades.map((u) {
                                  return DropdownMenuItem<int>(
                                    value: u['id'],
                                    child: Text(
                                      u['nombre'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (nuevoId) {
                                  setState(() => _selectedUnidadId = nuevoId);
                                  _cargarCargos(nuevoId!); 
                                },
                                validator: (v) =>
                                    v == null ? 'Seleccione Unidad' : null,
                              ),
                        const SizedBox(height: 20),

                        _buildLabel(Icons.work, "Cargo Específico *"),
                        _isLoadingCargos
                            ? const LinearProgressIndicator(
                                color: Color(0xFFFFD54F),
                              )
                            : DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: _selectedCargoId,
                                decoration: _inputDecoration(
                                  _selectedUnidadId == null
                                      ? "Primero seleccione una Unidad"
                                      : "Seleccione el Cargo",
                                ),
                                items: _listaCargos.map((c) {
                                  return DropdownMenuItem<int>(
                                    value: c['id'],
                                    child: Text(
                                      c['nombre'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _selectedUnidadId == null
                                    ? null
                                    : (nuevoId) => setState(
                                        () => _selectedCargoId = nuevoId,
                                      ),
                                validator: (v) =>
                                    v == null ? 'Seleccione Cargo' : null,
                              ),
                        const SizedBox(height: 35),

                        // =====================================
                        // BOTONES DE ACCIÓN
                        // =====================================
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _guardarCambios,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black87,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _isSaving ? "Guardando..." : "Guardar Cambios",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD54F),
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildLabel(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(hint),
      validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
      ),
    );
  }
}