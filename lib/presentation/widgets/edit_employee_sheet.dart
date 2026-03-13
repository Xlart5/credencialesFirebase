import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/constans/constants/environment.dart';
import '../../config/models/employee_model.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';

// Función pública para llamar al panel desde la tabla
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

  // ==========================================
  // VARIABLES PARA LA API
  // ==========================================
  final String _baseUrl = Environment.apiUrl; // URL de tu Spring Boot

  List<dynamic> _listaUnidades = [];
  List<dynamic> _listaCargos = [];

  int? _selectedUnidadId;
  int? _selectedCargoId;

  bool _isSaving = false;
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

    // Iniciamos la descarga de las unidades apenas se abre el panel
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

          // Buscar el ID de la unidad actual del empleado (Comparando textos)
          final currentUnidadStr = widget.employee.unidad.trim().toUpperCase();
          for (var u in _listaUnidades) {
            if (u['nombre'].toString().trim().toUpperCase() ==
                currentUnidadStr) {
              _selectedUnidadId = u['id'];
              break;
            }
          }

          // Si encontramos su unidad, descargamos sus cargos inmediatamente
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
      _listaCargos = []; // Limpiamos la lista anterior
      _selectedCargoId = null; // Reseteamos el cargo
    });

    try {
      // Endpoint dinámico según la unidad seleccionada
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

          // Buscar el ID del cargo actual del empleado (Comparando textos)
          final currentCargoStr = widget.employee.cargo.trim().toUpperCase();
          for (var c in _listaCargos) {
            if (c['nombre'].toString().trim().toUpperCase() ==
                currentCargoStr) {
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
  // GUARDAR CAMBIOS
  // ==========================================
  // ==========================================
  // GUARDAR CAMBIOS (CONECTADO A SPRING BOOT)
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

    // 🔥 ARMAMOS EL MAPA EXACTAMENTE COMO LO PIDE TU PROVIDER/SWAGGER
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

      // 🔥 EL DATO CLAVE: El ID numérico del cargo que el backend exige
      "cargoID": _selectedCargoId,
    };

    final provider = context.read<EmployeeProvider>();

    // Llamamos al Provider (este ya tiene la lógica de limpiar caché y recargar lista)
    bool success = await provider.updateEmployee(
      widget.employee.id,
      nuevosDatos,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        Navigator.pop(context); // Cerramos el modal
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
          width: 600, // Ancho perfecto para web
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
                // HEADER OSCURO (Estilo AddUnidad)
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
                              "ACTUALIZACIÓN DE DATOS Y ASIGNACIÓN",
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

                        // --- Fila 3: ASIGNACIÓN (CASCADA CON ENDPOINTS) ---
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
                                  _cargarCargos(
                                    nuevoId!,
                                  ); // Llama al endpoint de cargos
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
