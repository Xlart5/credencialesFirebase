import 'package:cached_network_image/cached_network_image.dart';
import 'package:carnetizacion/config/helpers/pdf_generator_service.dart';
import 'package:carnetizacion/config/provider/employee_provider.dart';
import 'package:carnetizacion/presentation/widgets/edit_employee_sheet.dart';
import 'package:carnetizacion/presentation/widgets/view_employee_sheet.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
// Importante para la navegación si usas editar
import '../../config/models/employee_model.dart';

import '../../config/theme/app_colors.dart';

class EmployeeDataSource extends DataTableSource {
  final List<Employee> employees;
  final BuildContext context;

  EmployeeDataSource(this.employees, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= employees.length) return null;
    final emp = employees[index];

    // Leemos el provider para saber si está seleccionado
    final provider = context.read<EmployeeProvider>();

    final bool esImpreso = emp.estado == 1;
    final Color colorEstado = esImpreso
        ? AppColors.successGreen
        : Colors.orange;
    final Color bgEstado = esImpreso
        ? AppColors.successGreen.withOpacity(0.1)
        : Colors.orange.withOpacity(0.1);

    return DataRow.byIndex(
      index: index,
      color: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        return index.isEven ? Colors.white : Colors.grey[50];
      }),

      // 🔥 1. Le decimos si la casilla debe estar marcada
      selected: provider.selectedForPrint.contains(emp),

      // 🔥 2. ¿Qué pasa cuando tocan la casilla o la fila?
      onSelectChanged: (bool? selected) {
        if (selected != null) {
          provider.toggleSelection(emp);
        }
      },

      cells: [
        // 1. FOTO (Solo Inicial, CERO consumo de internet)
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryDark.withOpacity(0.1),
              child: Text(
                emp.nombreCompleto.isNotEmpty
                    ? emp.nombreCompleto.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),

        // 2. NOMBRE
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emp.nombreCompleto,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // 3. CARGO
        DataCell(Text(emp.cargo, style: const TextStyle(fontSize: 12))),

        // 4. CÉDULA
        DataCell(
          Text(
            emp.ci,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),

        // 5. UNIDAD
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              emp.unidad,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // 6. ESTADO (Con colores restaurados)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgEstado,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: colorEstado),
                const SizedBox(width: 6),
                Text(
                  emp.estadoActual,
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 7. ACCIONES (4 Botones: Ver, Imprimir, Editar, Borrar)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize
                .min, // Importante para que no ocupen espacio infinito
            children: [
              // 🔥 VER: Abre el diálogo con la tarjeta de información detallada
              _ActionButton(
                icon: Icons.visibility_outlined,
                color: Colors.grey,
                onTap: () {
                  showViewEmployeeDialog(context, emp);
                },
              ),

              const SizedBox(width: 5),

              // IMPRIMIR CREDENCIAL (Mantiene tu lógica)
              _ActionButton(
                icon: Icons.print_outlined,
                color: AppColors.primaryDark,
                onTap: () async {
                  await Printing.layoutPdf(
                    onLayout: (format) async {
                      return await PdfGeneratorService.generateCredentialsPdf([
                        emp,
                      ]);
                    },
                    name: 'Credencial_${emp.ci}.pdf',
                  );

                  if (context.mounted) {
                    _preguntarSiImprimioBien(context, emp);
                  }
                },
              ),

              const SizedBox(width: 5),

              // 🔥 EDITAR: Abre el BottomSheet con el formulario para editar
              _ActionButton(
                icon: Icons.edit_outlined,
                color: Colors.blue,
                onTap: () {
                  showEditEmployeeSheet(context, emp);
                },
              ),

              const SizedBox(width: 5),

              // BORRAR (Mantiene tu lógica)
              _ActionButton(
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () {
                  _mostrarDialogoEliminar(context, emp);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget auxiliar para que los botones se vean uniformes
  Widget _ActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => employees.length;
  @override
  int get selectedRowCount => 0;
}

// ==========================================
// DIÁLOGOS (Eliminar e Imprimir)
// ==========================================

void _mostrarDialogoEliminar(BuildContext context, Employee emp) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            SizedBox(width: 10),
            Text("Eliminar Personal"),
          ],
        ),
        content: Text(
          "¿Estás seguro de que deseas eliminar a ${emp.nombre}? Esta acción es permanente y no se puede deshacer.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Cierra sin hacer nada
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Cerramos el diálogo primero

              // Llamamos al Provider para borrarlo en la BD
              final provider = context.read<EmployeeProvider>();
              bool success = await provider.deleteEmployee(emp.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Personal eliminado correctamente."
                          : "Error al eliminar. Intente de nuevo.",
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "Sí, Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

void _preguntarSiImprimioBien(BuildContext context, Employee emp) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("¿Impresión Exitosa?"),
          ],
        ),
        content: Text(
          "¿Se imprimió correctamente la credencial de ${emp.nombreCompleto}?\n\nSi aceptas, su estado cambiará automáticamente a 'CREDENCIAL IMPRESO'.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "No, mantener pendiente",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Cerramos el diálogo

              // Llamamos a tu Provider para actualizar la Base de Datos
              final provider = context.read<EmployeeProvider>();
              bool success = await provider.markAsPrinted(emp);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Estado actualizado correctamente."
                          : "Error al actualizar estado.",
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "Sí, actualizar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}
