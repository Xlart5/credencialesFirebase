import 'package:flutter/material.dart';

class AddCargoSheet extends StatefulWidget {
  const AddCargoSheet({super.key});

  @override
  State<AddCargoSheet> createState() => _AddCargoSheetState();
}

class _AddCargoSheetState extends State<AddCargoSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();

  String? _selectedEstado = 'Habilitado';
  String? _selectedColor;

  // Lista de estados
  final List<String> _estados = ['Habilitado', 'Inhabilitado'];

  // Lista de colores con su valor hexadecimal o material asociado para la UI
  final Map<String, Color> _colores = {
    'Verde': Colors.green,
    'Plomo': Colors.grey,
    'Blanco': Colors.white,
    'Naranja': Colors.orange,
    'Guindo': Colors.red.shade900,
    'Café': Colors.brown,
    'Externo': Colors.teal,
    'Planta': Colors.blueGrey,
  };

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _guardarCargo() {
    if (_formKey.currentState!.validate()) {
      // Aquí irá la lógica para guardar el cargo en tu Provider/API
      
      Navigator.pop(context); // Cierra el Bottom Sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargo registrado exitosamente'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Para que se ajuste si por alguna razón se abre el teclado
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: 500, // Ancho fijo para mantener la elegancia en web
      padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 30 + bottomInset),
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
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.work_outline, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 10),
                      const Text("Registrar nuevo cargo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(height: 30),

              // --- CAMPO: NOMBRE ---
              _buildSectionLabel("NOMBRE DEL CARGO *"),
              TextFormField(
                controller: _nombreCtrl,
                decoration: _inputDecoration("Ej. Soporte Técnico Nivel 2"),
                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),

              // --- CAMPO: ESTADO ---
              _buildSectionLabel("ESTADO *"),
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: _inputDecoration("Seleccione un estado"),
                items: _estados.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(estado),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedEstado = value),
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),

              // --- CAMPO: COLOR ---
              _buildSectionLabel("COLOR DE IDENTIFICACIÓN *"),
              DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: _inputDecoration("Seleccione un color"),
                items: _colores.keys.map((colorName) {
                  return DropdownMenuItem(
                    value: colorName,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _colores[colorName],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(colorName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedColor = value),
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 30),

              // --- BOTONES ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _guardarCargo,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text("Guardar Cargo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber, // Mantenemos el amarillo de tu diseño
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                      elevation: 0,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE APOYO PARA MANTENER EL DISEÑO LIMPIO ---
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blueAccent)),
    );
  }
}