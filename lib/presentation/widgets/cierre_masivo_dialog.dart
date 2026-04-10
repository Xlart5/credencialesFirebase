import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../config/constans/constants/environment.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';

class CierreMasivoDialog extends StatefulWidget {
  const CierreMasivoDialog({super.key});

  @override
  State<CierreMasivoDialog> createState() => _CierreMasivoDialogState();
}

class _CierreMasivoDialogState extends State<CierreMasivoDialog> {
  List<dynamic> _cargos = [];
  int? _selectedCargoId;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isLoadingCargos = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCargos();
  }

  // Descargamos los cargos directamente para asegurar que tenemos los IDs correctos (cargoProcesoId)
  Future<void> _fetchCargos() async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/api/cargos-proceso'),
        headers: Environment.authHeaders,
      );
      if (response.statusCode == 200) {
        setState(() {
          _cargos = json.decode(utf8.decode(response.bodyBytes));
          _isLoadingCargos = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingCargos = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.event_busy, color: Colors.redAccent, size: 28),
          SizedBox(width: 10),
          Text("Cierre Masivo por Cargo", style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Esta acción finalizará los contratos de todo el personal que pertenezca al cargo seleccionado.", style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
            const SizedBox(height: 25),

            // SELECCIÓN DE CARGO
            const Text("Seleccione el Cargo:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textGrey)),
            const SizedBox(height: 8),
            _isLoadingCargos
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                    hint: const Text("Elija un cargo..."),
                    value: _selectedCargoId,
                    items: _cargos.map((cargo) {
                      return DropdownMenuItem<int>(
                        value: cargo['id'],
                        child: Text(cargo['nombre'].toString(), style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCargoId = val),
                  ),
            const SizedBox(height: 20),

            // SELECCIÓN DE FECHAS
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    "Fecha de Inicio", 
                    _fechaInicio, 
                    () => _selectDate(context, true)
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildDateSelector(
                    "Fecha de Fin", 
                    _fechaFin, 
                    () => _selectDate(context, false)
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(20),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSubmitting ? null : () async {
            if (_selectedCargoId == null || _fechaInicio == null || _fechaFin == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complete todos los campos para continuar"), backgroundColor: Colors.orange));
              return;
            }

            setState(() => _isSubmitting = true);
            final provider = context.read<EmployeeProvider>();
            
            bool success = await provider.cerrarContratosMasivoPorCargo(
              cargoProcesoId: _selectedCargoId!,
              fechaInicio: _fechaInicio!,
              fechaFin: _fechaFin!
            );

            setState(() => _isSubmitting = false);

            if (context.mounted) {
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contratos cerrados exitosamente."), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al procesar el cierre masivo."), backgroundColor: Colors.red));
              }
            }
          },
          icon: _isSubmitting ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.gavel, size: 18),
          label: Text(_isSubmitting ? "Procesando..." : "Aplicar Cierre", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? "${date.day}/${date.month}/${date.year}" : "DD/MM/AAAA",
                  style: TextStyle(color: date != null ? Colors.black87 : Colors.grey, fontSize: 13),
                ),
                const Icon(Icons.calendar_month, size: 16, color: AppColors.primaryDark),
              ],
            ),
          ),
        ),
      ],
    );
  }
}