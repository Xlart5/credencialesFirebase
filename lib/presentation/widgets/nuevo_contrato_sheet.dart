import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/constans/constants/environment.dart';
import '../../config/models/employee_model.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';

void showNuevoContratoSheet(BuildContext context, Employee emp) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => NuevoContratoSheet(employee: emp),
  );
}

class NuevoContratoSheet extends StatefulWidget {
  final Employee employee;
  const NuevoContratoSheet({super.key, required this.employee});

  @override
  State<NuevoContratoSheet> createState() => _NuevoContratoSheetState();
}

class _NuevoContratoSheetState extends State<NuevoContratoSheet> {
  final String _baseUrl = Environment.apiUrl;

  List<dynamic> _listaUnidades = [];
  List<dynamic> _listaCargos = [];

  int? _selectedUnidadId;
  int? _selectedCargoId;

  bool _isLoadingUnidades = true;
  bool _isLoadingCargos = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarUnidades();
  }

  Future<void> _cargarUnidades() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/unidades'),
        headers: Environment.authHeaders,
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _listaUnidades =
                json.decode(utf8.decode(response.bodyBytes)) as List;
            _isLoadingUnidades = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUnidades = false);
    }
  }

  Future<void> _cargarCargos(int unidadId) async {
    setState(() {
      _isLoadingCargos = true;
      _listaCargos = [];
      _selectedCargoId = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cargos-proceso/unidad/$unidadId'),
        headers: Environment.authHeaders,
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _listaCargos = json.decode(utf8.decode(response.bodyBytes)) as List;
            _isLoadingCargos = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCargos = false);
    }
  }

  Future<void> _generarNuevoContrato() async {
    if (_selectedCargoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seleccione Unidad y Cargo"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<EmployeeProvider>();

    // El provider ya se encarga de poner la fecha de inicio automática
    bool success = await provider.registrarNuevoContrato(
      widget.employee,
      _selectedCargoId!,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context); // Cierra modal actual
        Navigator.pop(context); // Cierra el modal de evaluación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Contrato iniciado exitosamente"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al registrar. Revise los datos."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.autorenew, color: Colors.white, size: 28),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Registrar Nuevo Contrato\n${widget.employee.nombre}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Para activar nuevamente a esta persona, asígnele su nueva unidad y cargo:",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 25),

                    // UNIDAD
                    const Text(
                      "Unidad / Departamento",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingUnidades
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                            ),
                            hint: const Text("Seleccione Unidad"),
                            value: _selectedUnidadId,
                            isExpanded: true,
                            items: _listaUnidades
                                .map(
                                  (u) => DropdownMenuItem<int>(
                                    value: u['id'],
                                    child: Text(
                                      u['nombre'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedUnidadId = val);
                              _cargarCargos(val!);
                            },
                          ),
                    const SizedBox(height: 20),

                    // CARGO
                    const Text(
                      "Nuevo Cargo",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingCargos
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                            ),
                            hint: Text(
                              _selectedUnidadId == null
                                  ? "Primero seleccione Unidad"
                                  : "Seleccione Cargo",
                            ),
                            value: _selectedCargoId,
                            isExpanded: true,
                            items: _listaCargos
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c['id'],
                                    child: Text(
                                      c['nombre'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _selectedUnidadId == null
                                ? null
                                : (val) =>
                                      setState(() => _selectedCargoId = val),
                          ),
                    const SizedBox(height: 35),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _generarNuevoContrato,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          _isSaving ? "Registrando..." : "Crear Nuevo Contrato",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
