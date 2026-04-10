import 'package:carnetizacion/config/provider/employee_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import 'employee_datasource.dart';

// 🔥 IMPORTAMOS EL AUTH PROVIDER
import '../../config/provider/auth_provider.dart';

class EmployeesTable extends StatefulWidget {
  const EmployeesTable({super.key});

  @override
  State<EmployeesTable> createState() => _EmployeesTableState();
}

class _EmployeesTableState extends State<EmployeesTable> {
  int _filasPorPagina = 10;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final dataSource = EmployeeDataSource(provider.employees, context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _buildHeader(context),
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
                  DataColumn(label: Text("Personal")),
                  DataColumn(label: Text("Cargo")),
                  DataColumn(label: Text("Cédula (CI)")),
                  DataColumn(label: Text("Circunscripción / Unidad")),
                  DataColumn(label: Text("Estado")),
                  DataColumn(label: Text("Acciones")),
                ],
                source: dataSource,
                header: const Text("Padrón de Personal Registrado"),
                rowsPerPage: _filasPorPagina,
                availableRowsPerPage: const [10, 20, 50, 100],
                onRowsPerPageChanged: (nuevoValor) {
                  if (nuevoValor != null) {
                    setState(() {
                      _filasPorPagina = nuevoValor;
                    });
                  }
                },
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
    
    // ==========================================
    // 🛡️ LÓGICA DE ROLES (RBAC) INSTITUCIONAL
    // ==========================================
    final authProvider = context.watch<AuthProvider>();
    final String rolActual = authProvider.currentUser?.rol ?? 'OBSERVADOR';
    
    // Solo Admin y Coordinador pueden crear nuevos registros
    final bool puedeCrear = (rolActual == 'ADMINISTRADOR' || rolActual == 'COORDINADOR');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.how_to_reg, color: AppColors.primaryDark),
            SizedBox(width: 10),
            Text(
              "Gestión de Personal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  isDense: true,
                ),
              ),
            ),
            
            // 🔥 ESCUDO: Solo dibujamos el botón si tiene permisos
            if (puedeCrear) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/registro'); 
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text("Registrar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}