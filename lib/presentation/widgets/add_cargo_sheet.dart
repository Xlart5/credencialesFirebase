import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/provider/unidades_provider.dart';

class AddCargoSheet extends StatefulWidget {
  final int unidadId;

  const AddCargoSheet({super.key, required this.unidadId});

  @override
  State<AddCargoSheet> createState() => _AddCargoSheetState();
}

class _AddCargoSheetState extends State<AddCargoSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();

  String? _selectedEstado = 'Habilitado';
  String? _selectedColor;
  bool _isSubmitting = false;

  final List<String> _estados = ['Habilitado', 'Inhabilitado'];

  final Map<String, String> _colores = {
    'Planta': "PLANTA",
    'Eventual': "EVENTUAL",
  };

  final Map<String, IconData> _iconos = {
    'Planta': Icons.other_houses_outlined,
    'Eventual': Icons.hourglass_empty_outlined,
  };

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  // =====================================
  // LÓGICA PARA GUARDAR EN SPRING BOOT
  // =====================================
  Future<void> _guardarCargo() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final provider = context.read<UnidadesProvider>();

      String nombreFinal =
          "${_nombreCtrl.text.trim()} (${_selectedColor?.toUpperCase()})";
      String tipofinal = "${_selectedColor?.toUpperCase()}";

      bool success = await provider.addCargo(
        nombreFinal,
        widget.unidadId,
        tipofinal,
      );

      setState(() => _isSubmitting = false);

      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cargo registrado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar el cargo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: 500,
      padding: EdgeInsets.only(
        left: 30,
        right: 30,
        top: 30,
        bottom: 30 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Registrar nuevo cargo",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 30),

              _buildSectionLabel("NOMBRE DEL CARGO *"),
              TextFormField(
                controller: _nombreCtrl,
                decoration: _inputDecoration("Ej. Soporte Técnico Nivel 2"),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),

              _buildSectionLabel("ESTADO *"),
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: _inputDecoration("Seleccione un estado"),
                items: _estados.map((estado) {
                  return DropdownMenuItem(value: estado, child: Text(estado));
                }).toList(),
                onChanged: (value) => setState(() => _selectedEstado = value),
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),

              _buildSectionLabel("Tipo de Cargo *"),
              DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: _inputDecoration("Seleccione un Tipo"),
                items: _colores.keys.map((tipoName) {
                  return DropdownMenuItem(
                    value: tipoName,
                    child: Row(
                      children: [
                        Icon(
                          _iconos[tipoName],
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(tipoName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedColor = value),
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 30),

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
                    onPressed: _isSubmitting ? null : _guardarCargo,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black87,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      _isSubmitting ? "Guardando..." : "Guardar Cargo",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 18,
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }
}
