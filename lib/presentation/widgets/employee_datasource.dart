import 'package:carnetizacion/config/helpers/pdf_generator_service.dart';
import 'package:carnetizacion/config/provider/employee_provider.dart';
import 'package:carnetizacion/presentation/widgets/edit_employee_sheet.dart';
import 'package:carnetizacion/presentation/widgets/view_employee_sheet.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../config/models/employee_model.dart';
import '../../config/theme/app_colors.dart';

// 🔥 IMPORTAMOS EL AUTH PROVIDER
import '../../config/provider/auth_provider.dart';

class EmployeeDataSource extends DataTableSource {
  final List<Employee> employees;
  final BuildContext context;

  EmployeeDataSource(this.employees, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= employees.length) return null;
    final emp = employees[index];

    final provider = context.read<EmployeeProvider>();

    // ==========================================
    // 🛡️ LÓGICA DE ROLES (RBAC)
    // ==========================================
    final authProvider = context.read<AuthProvider>();
    final String rolActual = authProvider.currentUser?.rol ?? 'OBSERVADOR';
    
    final bool puedeEditar = (rolActual == 'ADMINISTRADOR' || rolActual == 'COORDINADOR');
    final bool puedeEliminar = (rolActual == 'ADMINISTRADOR');
    // ==========================================

    final bool esImpreso = emp.estado == 1;
    final Color colorEstado = esImpreso ? AppColors.successGreen : Colors.orange;
    final Color bgEstado = esImpreso ? AppColors.successGreen.withOpacity(0.1) : Colors.orange.withOpacity(0.1);

    return DataRow.byIndex(
      index: index,
      color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        return index.isEven ? Colors.white : Colors.grey[50];
      }),

      selected: provider.selectedForPrint.contains(emp),

      // 🔥 ESCUDO: Anulamos la selección para los observadores
      onSelectChanged: puedeEditar ? (bool? selected) {
        if (selected != null) {
          provider.toggleSelection(emp);
        }
      } : null, 

      cells: [
        // 1. FOTO 
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryDark.withOpacity(0.1),
              child: Text(
                emp.nombreCompleto.isNotEmpty ? emp.nombreCompleto.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 16),
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
              Text(emp.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
            ],
          ),
        ),

        // 3. CARGO
        DataCell(Text(emp.cargo, style: const TextStyle(fontSize: 12))),

        // 4. CÉDULA
        DataCell(Text(emp.ci, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),

        // 5. UNIDAD
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
            child: Text(emp.unidad, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ),
        ),

        // 6. ESTADO 
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bgEstado, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: colorEstado),
                const SizedBox(width: 6),
                Text(emp.estadoActual, style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ),

        // 7. ACCIONES
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔥 VER: Lo ven todos
              _ActionButton(
                icon: Icons.visibility_outlined,
                color: Colors.blueGrey,
                onTap: () {
                  showViewEmployeeDialog(context, emp);
                },
              ),

              // 🔥 IMPRIMIR: Solo Admin y Coordinador
              if (puedeEditar) ...[
                const SizedBox(width: 5),
                _ActionButton(
                  icon: Icons.print_outlined,
                  color: AppColors.primaryDark,
                  onTap: () async {
                    await Printing.layoutPdf(
                      onLayout: (format) async {
                        return await PdfGeneratorService.generateCredentialsPdf([emp]);
                      },
                      name: 'Credencial_OEP_${emp.ci}.pdf',
                    );
                    if (context.mounted) {
                      _preguntarSiImprimioBien(context, emp);
                    }
                  },
                ),
              ],

              // 🔥 EDITAR: Solo Admin y Coordinador
              if (puedeEditar) ...[
                const SizedBox(width: 5),
                _ActionButton(
                  icon: Icons.edit_outlined,
                  color: Colors.blue,
                  onTap: () {
                    showEditEmployeeSheet(context, emp);
                  },
                ),
              ],

              // 🔥 BORRAR: Solo Administrador
              if (puedeEliminar) ...[
                const SizedBox(width: 5),
                _ActionButton(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: () {
                    _mostrarDialogoEliminar(context, emp);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _ActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
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
// DIÁLOGOS (Eliminar e Imprimir) Mantenidos iguales
// ==========================================

void _mostrarDialogoEliminar(BuildContext context, Employee emp) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Eliminar Registro"),
          ],
        ),
        content: Text("¿Está seguro de que desea eliminar los datos de ${emp.nombre}? Esta acción retirará al personal de la base de datos.", style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop(); 
              final provider = context.read<EmployeeProvider>();
              bool success = await provider.deleteEmployee(emp.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Registro eliminado correctamente." : "Error al eliminar en el servidor."),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Sí, Eliminar", style: TextStyle(color: Colors.white)),
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
            Text("Confirmar Impresión"),
          ],
        ),
        content: Text("¿Se imprimió correctamente la credencial electoral de ${emp.nombreCompleto}?\n\nAl confirmar, el estado cambiará a 'CREDENCIAL IMPRESA'.", style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("No, mantener estado actual", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen),
            onPressed: () async {
              Navigator.of(ctx).pop(); 
              final provider = context.read<EmployeeProvider>();
              bool success = await provider.markAsPrinted(emp);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Estado actualizado en el padrón." : "Error de sincronización."),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Sí, confirmar", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}