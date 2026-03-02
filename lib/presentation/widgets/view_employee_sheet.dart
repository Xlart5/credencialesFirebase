import 'package:flutter/material.dart';
import '../../config/models/employee_model.dart';
import '../../config/theme/app_colors.dart';

// Función pública para llamar al diálogo desde cualquier parte
void showViewEmployeeDialog(BuildContext context, Employee emp) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(25),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FOTO
            CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.primaryDark.withOpacity(0.1),
              backgroundImage: (emp.photoUrl.isNotEmpty)
                  ? NetworkImage(emp.photoUrl)
                  : null,
              child: (emp.photoUrl.isEmpty)
                  ? Text(
                      emp.nombreCompleto.isNotEmpty
                          ? emp.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 30,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 15),
            Text(
              emp.nombreCompleto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                emp.cargo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(),
            ),

            // DATOS COMPLETOS
            _infoRow(icon: Icons.badge_outlined, label: "C.I.", value: emp.ci),
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.business_outlined,
              label: "Unidad",
              value: emp.unidad,
            ),
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.phone_android_outlined,
              label: "Celular",
              value: emp.celular.isNotEmpty ? emp.celular : "No registrado",
            ),
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.email_outlined,
              label: "Correo",
              value: emp.correo ?? "No registrado",
            ),
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.info_outline,
              label: "Estado",
              value: emp.estadoActual,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cerrar", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

// Fila reutilizable para el diseño
Widget _infoRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: Colors.grey[600]),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}
