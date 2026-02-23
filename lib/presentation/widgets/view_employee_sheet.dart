import 'package:flutter/material.dart';
import '../../config/models/employee_model.dart';

class ViewEmployeeSheet extends StatelessWidget {
  final Employee employee;

  const ViewEmployeeSheet({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500, // Ancho fijo para que se vea elegante en la web
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  const Icon(Icons.person_search, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  const Text(
                    "Detalles del Registro",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

          // --- FOTO Y ESTADO ---
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: NetworkImage(employee.photoUrl),
                  onBackgroundImageError: (_, __) =>
                      const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                // Insignia de Estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: employee.estado == 1
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    border: Border.all(color: employee.colorEstado),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "ESTADO: ${employee.estadoActual.toUpperCase()}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: employee.colorEstado,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // --- DATOS DEL EMPLEADO ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDataColumn("Nombres", employee.nombre)),
              Expanded(
                child: _buildDataColumn(
                  "Apellidos",
                  "${employee.apellidoPaterno} ${employee.apellidoMaterno}",
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDataColumn("Cédula de Identidad", employee.ci),
              ),
              Expanded(
                child: _buildDataColumn("Unidad / Sección", employee.unidad),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildDataColumn("Cargo Asignado", employee.cargo),
          const SizedBox(height: 30),

          // --- BOTÓN DE CERRAR ---
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: const Text("Cerrar"),
            ),
          ),
        ],
      ),
    );
  }

  // Widget de ayuda para mostrar los datos ordenados
  Widget _buildDataColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ],
    );
  }
}
