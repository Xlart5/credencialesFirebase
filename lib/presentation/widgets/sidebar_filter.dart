import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';

class SidebarFilter extends StatelessWidget {
  const SidebarFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    // Usamos allEmployees para que el número de la burbuja no cambie al filtrar
    final allEmp = provider.allEmployees;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 20, top: 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TÍTULO
          Row(
            children: const [
              Icon(Icons.filter_list, color: AppColors.primaryYellow),
              SizedBox(width: 10),
              Text(
                "Filtros Rápidos",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 15),

          // 2. SECCIÓN UNIDADES
          const Text(
            "UNIDAD DESTINADA",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 15),

          // LISTA DINÁMICA DE UNIDADES
          ...provider.unidadesDisponibles.map((unidad) {
            // Verificamos si este botón está presionado
            final isSelected = provider.selectedUnidadFilter == unidad;
            // Contamos cuántas personas pertenecen a esta unidad
            final count = allEmp.where((e) => e.unidad == unidad).length;

            return _buildUnidadItem(
              title: unidad,
              count: count,
              isSelected: isSelected,
              onTap: () => provider.toggleUnidadFilter(unidad),
            );
          }).toList(),

          const SizedBox(height: 30),

          // 3. SECCIÓN ESTADOS
          const Text(
            "ESTADO",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 15),

          // CHIPS DINÁMICOS DE ESTADOS
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: provider.estadosDisponibles.map((estado) {
              final isSelected = provider.selectedEstadoFilter == estado;

              // Lógica de colores según la palabra
              Color baseColor = Colors.grey;
              if (estado.toUpperCase().contains('IMPRESO'))
                baseColor = Colors.green;
              if (estado.toUpperCase().contains('REGISTRADO') ||
                  estado.toUpperCase().contains('PENDIENTE'))
                baseColor = Colors.orange;

              return _buildEstadoChip(
                estado: estado,
                isSelected: isSelected,
                baseColor: baseColor,
                onTap: () => provider.toggleEstadoFilter(estado),
              );
            }).toList(),
          ),

          const Spacer(), // Empuja el botón limpiar al fondo
          // 4. BOTÓN LIMPIAR FILTROS (Solo aparece si hay algún filtro activo)
          if (provider.selectedUnidadFilter != null ||
              provider.selectedEstadoFilter != null ||
              provider.searchQuery.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => provider.clearFilters(),
                icon: const Icon(
                  Icons.clear_all,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: const Text(
                  "Limpiar Filtros",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================
  // WIDGET AUXILIAR: BOTÓN DE UNIDAD
  // =====================================
  Widget _buildUnidadItem({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================
  // WIDGET AUXILIAR: BOTÓN DE ESTADO (CHIP)
  // =====================================
  Widget _buildEstadoChip({
    required String estado,
    required bool isSelected,
    required Color baseColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? baseColor : baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? baseColor : Colors.transparent,
          ),
        ),
        child: Text(
          estado,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : baseColor,
          ),
        ),
      ),
    );
  }
}
