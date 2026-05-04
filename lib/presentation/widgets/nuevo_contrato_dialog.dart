import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/constans/constants/environment.dart';
import '../../config/models/employee_model.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';

class NuevoContratoDialog extends StatefulWidget {
  final Employee empleado;
  const NuevoContratoDialog({super.key, required this.empleado});

  @override
  State<NuevoContratoDialog> createState() => _NuevoContratoDialogState();
}

class _NuevoContratoDialogState extends State<NuevoContratoDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _cargos = [];
  int? _selectedCargoId;

  @override
  void initState() {
    super.initState();
    _fetchCargos();
  }

  // Descargamos los cargos del endpoint público sin authHeaders (para evitar el 403)
  Future<void> _fetchCargos() async {
    try {
      final url = Uri.parse('${Environment.apiUrl}/api/cargos-proceso');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      
      if (response.statusCode == 200) {
        setState(() {
          _cargos = json.decode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _iniciarContrato() async {
    if (_selectedCargoId == null) return;

    setState(() => _isSaving = true);
    final provider = context.read<EmployeeProvider>();
    
    // Ejecutamos tu función maestra del provider
    final success = await provider.registrarNuevoContrato(widget.empleado, _selectedCargoId!);
    
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context); // Cerramos el dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Contrato iniciado. ${widget.empleado.nombre} ha vuelto a estado REGISTRADO."), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al procesar el nuevo contrato."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Asignar Nuevo Cargo", style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estás a punto de reincorporar a:", style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 5),
            Text(widget.empleado.nombreCompleto, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: "Selecciona el Nuevo Cargo",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  isExpanded: true,
                  value: _selectedCargoId,
                  items: _cargos.map((cargo) {
                    return DropdownMenuItem<int>(
                      value: cargo['id'],
                      child: Text(cargo['nombre'], overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCargoId = val),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: (_selectedCargoId == null || _isSaving) ? null : _iniciarContrato,
          child: _isSaving 
            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Text("Confirmar e Iniciar"),
        ),
      ],
    );
  }
}