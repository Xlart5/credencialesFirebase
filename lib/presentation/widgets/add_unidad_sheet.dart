import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/provider/unidades_provider.dart';

class AddUnidadSheet extends StatefulWidget {
  const AddUnidadSheet({super.key});

  @override
  State<AddUnidadSheet> createState() => _AddUnidadSheetState();
}

class _AddUnidadSheetState extends State<AddUnidadSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _abrevCtrl = TextEditingController();

  bool _isActivo = true; // Para el diseño de los botones "Activo / Inactivo"
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _abrevCtrl.dispose();
    super.dispose();
  }

  // =====================================
  // LÓGICA PARA GUARDAR EN SPRING BOOT
  // =====================================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<UnidadesProvider>();

    // Llamamos a la función que conecta con la API
    final success = await provider.addUnidad(
      _nombreCtrl.text.trim(),
      _abrevCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        Navigator.pop(context); // Cerramos el panel
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unidad registrada con éxito"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al registrar la unidad"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Permite que el teclado no tape el contenido
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: const EdgeInsets.only(bottom: 200),
      child: Center(
        // 🔥 CENTRAMOS EL MODAL PARA PANTALLAS GRANDES
        child: Container(
          width: 500, // 🔥 ANCHO FIJO PARA MANTENER LA ELEGANCIA EN WEB
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
              bottom: Radius.circular(25),
            ),
          ),
          // Ajustamos el padding inferior para el teclado
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
                    color: Color(0xFF1E2B5E), // Azul oscuro de tu diseño
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.domain,
                        color: Color(0xFFFFD54F),
                        size: 28,
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nueva Unidad",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "GESTIÓN INSTITUCIONAL",
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
                // FORMULARIO (BODY)
                // =====================================
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Registrar Unidad",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2B5E),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Ingrese la información técnica para dar de alta la unidad en el sistema.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 25),

                        // CAMPO 1: NOMBRE
                        _buildLabel(
                          Icons.business_center,
                          "Nombre de la Unidad",
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: _inputDecoration(
                            "Ej: Secretaría de Cámara",
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Este campo es requerido" : null,
                        ),
                        const SizedBox(height: 20),

                        // CAMPO 2: ABREVIATURA
                        _buildLabel(Icons.short_text, "Abreviatura (Sigla)"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _abrevCtrl,
                          decoration: _inputDecoration("Ej: SC"),
                          validator: (value) =>
                              value!.isEmpty ? "Este campo es requerido" : null,
                        ),
                        const SizedBox(height: 20),

                        // CAMPO 3: ESTADO INICIAL (ESTILO TOGGLE)
                        _buildLabel(Icons.toggle_on, "Estado Inicial"),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStateButton(
                                title: "Activa",
                                isSelected: _isActivo,
                                onTap: () => setState(() => _isActivo = true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStateButton(
                                title: "Inactiva",
                                isSelected: !_isActivo,
                                onTap: () => setState(() => _isActivo = false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),

                        // =====================================
                        // BOTONES DE ACCIÓN
                        // =====================================
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitForm,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors
                                          .black87, // Color visible en el botón amarillo
                                    ),
                                  )
                                : const Icon(Icons.add_circle),
                            label: Text(
                              _isSubmitting
                                  ? "Guardando..."
                                  : "Registrar Unidad",
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

  // --- WIDGETS AUXILIARES PARA LIMPIAR EL CÓDIGO ---

  Widget _buildLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
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

  Widget _buildStateButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9E6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD54F) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
