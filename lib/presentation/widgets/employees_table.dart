import 'package:carnetizacion/config/provider/employee_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import 'employee_datasource.dart';

class EmployeesTable extends StatelessWidget {
  const EmployeesTable({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    // Conectamos los datos del provider con nuestra fuente de la tabla
    final dataSource = EmployeeDataSource(provider.employees, context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context), // Aquí es donde realmente se dibuja el botón
          const SizedBox(height: 20),

          if (provider.isLoading)
            const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Theme(
              data: Theme.of(context).copyWith(
                cardColor: Colors.white,
                dividerColor: Colors.grey[200],
              ),
              child: PaginatedDataTable(
                columns: const [
                  DataColumn(label: Text("Foto")),
                  DataColumn(label: Text("Empleado")),
                  DataColumn(label: Text("Cargo")),
                  DataColumn(label: Text("Cédula (CI)")),
                  DataColumn(label: Text("Unidad")),
                  DataColumn(label: Text("Estado")),
                  DataColumn(label: Text("Acciones")),
                ],
                source: dataSource,
                header: const Text("Listado Oficial"),
                rowsPerPage: 10,
                availableRowsPerPage: const [10, 20, 50],
                onRowsPerPageChanged: (value) {},
                showCheckboxColumn: true,
                columnSpacing: 20,
                horizontalMargin: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final provider = context.read<EmployeeProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.list_alt, color: AppColors.primaryYellow),
            SizedBox(width: 10),
            Text(
              "Gestión de Empleados",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(
              width: 250,
              child: TextField(
                onChanged: (value) => provider.search(value),
                decoration: InputDecoration(
                  hintText: "Buscar por CI o Nombre...",
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ✅ AQUÍ ES DONDE DEBES PONER LA NAVEGACIÓN
            ElevatedButton.icon(
              onPressed: () {
                context.go('/registro'); // <--- ¡AQUÍ VA!
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Nuevo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
