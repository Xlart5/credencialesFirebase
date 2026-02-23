import 'package:carnetizacion/config/provider/employee_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/models/employee_model.dart';

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
  late TextEditingController _cargoCtrl;
  late TextEditingController _unidadCtrl;

  @override
  void initState() {
    super.initState();
    // Pre-cargamos los datos actuales del empleado
    _nombreCtrl = TextEditingController(text: widget.employee.nombre);
    _paternoCtrl = TextEditingController(text: widget.employee.apellidoPaterno);
    _maternoCtrl = TextEditingController(text: widget.employee.apellidoMaterno);
    _ciCtrl = TextEditingController(text: widget.employee.ci);
    _cargoCtrl = TextEditingController(text: widget.employee.cargo);
    _unidadCtrl = TextEditingController(text: widget.employee.unidad);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _paternoCtrl.dispose();
    _maternoCtrl.dispose();
    _ciCtrl.dispose();
    _cargoCtrl.dispose();
    _unidadCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // 1. Creamos la copia con los nuevos datos
      final updatedEmployee = widget.employee.copyWith(
        nombre: _nombreCtrl.text.trim(),
        apellidoPaterno: _paternoCtrl.text.trim(),
        apellidoMaterno: _maternoCtrl.text.trim(),
        carnetIdentidad: _ciCtrl.text.trim(),
        cargo: _cargoCtrl.text.trim(),
        unidad: _unidadCtrl.text.trim(),
      );

      // 2. Actualizamos localmente para que la tabla cambie de inmediato
      context.read<EmployeeProvider>().updateEmployeeLocal(updatedEmployee);

      // 3. Cerramos el panel
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos actualizados en la tabla.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Limitamos el ancho para que no se vea gigante en monitores anchos
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Editar Información del Empleado",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const Divider(height: 30),

            // --- CAMPOS DE TEXTO (Diseño web en filas) ---
            Row(
              children: [
                Expanded(child: _buildTextField("Nombre", _nombreCtrl)),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTextField("Apellido Paterno", _paternoCtrl),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTextField("Apellido Materno", _maternoCtrl),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildTextField("Cédula de Identidad (CI)", _ciCtrl),
                ),
                const SizedBox(width: 15),
                Expanded(flex: 2, child: _buildTextField("Cargo", _cargoCtrl)),
                const SizedBox(width: 15),
                Expanded(
                  flex: 2,
                  child: _buildTextField("Unidad / Sección", _unidadCtrl),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- BOTONES ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text("Guardar Cambios"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget de apoyo para construir inputs limpios
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Este campo es requerido' : null,
    );
  }
}
