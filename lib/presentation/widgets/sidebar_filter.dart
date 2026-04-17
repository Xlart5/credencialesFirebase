import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';

class SidebarFilter extends StatefulWidget {
  final bool hideEstados; 
  final bool showImpresoFilter; // 🔥 NUEVO PARÁMETRO
  const SidebarFilter({super.key, this.hideEstados = false, this.showImpresoFilter = false});

  @override
  State<SidebarFilter> createState() => _SidebarFilterState();
}

class _SidebarFilterState extends State<SidebarFilter> {
  final MenuController _menuController = MenuController();
  bool _esConsulta = false;

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

  Future<void> _cargarRol() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _esConsulta = prefs.getString('rol') == 'CONSULTA';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    final MenuStyle modernMenuStyle = MenuStyle(
      backgroundColor: MaterialStateProperty.all(Colors.white),
      surfaceTintColor: MaterialStateProperty.all(Colors.white),
      elevation: MaterialStateProperty.all(6),
      shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.15)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 8)),
    );

    final ButtonStyle modernItemStyle = ButtonStyle(
      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.hovered)) return AppColors.primaryDark;
        return Colors.black87;
      }),
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.hovered)) return Colors.blueGrey.withOpacity(0.08);
        return Colors.white;
      }),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );

    List<Widget> buildAdminMenu() {
      return [
        MenuItemButton(
          style: modernItemStyle,
          onPressed: () => provider.setUnidadYCargo(null, null),
          child: const Text('TODAS LAS UNIDADES', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        ),
        const PopupMenuDivider(),
        ...provider.unidadesDisponibles.map((unidad) {
          return SubmenuButton(
            menuStyle: modernMenuStyle,
            style: modernItemStyle,
            menuChildren: [
              MenuItemButton(
                style: modernItemStyle,
                onPressed: () => provider.setUnidadYCargo(unidad, null),
                child: const Text('Todos los Cargos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
              ...(provider.cargosPorUnidad[unidad] ?? []).map((cargo) {
                return MenuItemButton(
                  style: modernItemStyle,
                  onPressed: () => provider.setUnidadYCargo(unidad, cargo),
                  child: Text(cargo),
                );
              }).toList(),
            ],
            child: Text(unidad), 
          );
        }).toList(),
      ];
    }

    List<Widget> buildConsultaMenu() {
      final miUnidad = provider.selectedUnidadFilter;
      if (miUnidad == null) return [const MenuItemButton(child: Text('Cargando...'))];

      final misCargos = provider.cargosPorUnidad[miUnidad] ?? [];

      return [
        MenuItemButton(
          style: modernItemStyle,
          onPressed: () => provider.setUnidadYCargo(miUnidad, null),
          child: const Text('Todos los Cargos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        ),
        const PopupMenuDivider(),
        ...misCargos.map((cargo) {
          return MenuItemButton(
            style: modernItemStyle,
            onPressed: () => provider.setUnidadYCargo(miUnidad, cargo),
            child: Text(cargo),
          );
        }).toList(),
      ];
    }

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.filter_list, color: AppColors.primaryYellow),
                SizedBox(width: 10),
                Text(
                  "Filtros Rápidos",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 15),

            const Text(
              "UNIDAD Y CARGO",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: 10),

            MouseRegion(
              onEnter: (_) {
                if (!_menuController.isOpen) {
                  _menuController.open();
                }
              },
              child: MenuAnchor(
                controller: _menuController,
                style: modernMenuStyle,
                menuChildren: _esConsulta ? buildConsultaMenu() : buildAdminMenu(),
                builder: (context, controller, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.selectedUnidadFilter == null
                                ? 'Seleccionar Unidad...'
                                : '${provider.selectedUnidadFilter}\n${provider.selectedCargoFilter ?? 'Todos los cargos'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 11, height: 1.3),
                            maxLines: 3, 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🔥 NUEVO: SECCIÓN DEL FILTRO IMPRESO (SÓLO SI ESTÁ ACTIVADO)
            if (widget.showImpresoFilter) ...[
              const SizedBox(height: 25),
              const Text(
                "¿ESTÁ IMPRESO?",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text("Sí", style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: provider.filtroImpreso == true,
                    onSelected: (selected) => provider.setFiltroImpreso(selected ? true : null),
                    selectedColor: Colors.green.shade200,
                  ),
                  ChoiceChip(
                    label: const Text("No", style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: provider.filtroImpreso == false,
                    onSelected: (selected) => provider.setFiltroImpreso(selected ? false : null),
                    selectedColor: Colors.orange.shade200,
                  ),
                ],
              ),
            ],

            if (!widget.hideEstados) ...[
              const SizedBox(height: 25),
              const Text(
                "ESTADO",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
              ),
              const SizedBox(height: 15),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: provider.estadosDisponibles.map((estado) {
                  final isSelected = provider.selectedEstadoFilter == estado;
                  Color baseColor = Colors.grey;
                  if (estado.toUpperCase().contains('IMPRESO')) baseColor = Colors.green;
                  if (estado.toUpperCase().contains('REGISTRADO') || estado.toUpperCase().contains('PENDIENTE')) baseColor = Colors.orange;

                  return _buildEstadoChip(
                    estado: estado,
                    isSelected: isSelected,
                    baseColor: baseColor,
                    onTap: () => provider.toggleEstadoFilter(estado),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 25),

            if (provider.selectedUnidadFilter != null ||
                provider.selectedCargoFilter != null ||
                provider.selectedEstadoFilter != null ||
                provider.filtroImpreso != null ||
                provider.searchQuery.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => provider.clearFilters(),
                  icon: const Icon(Icons.clear_all, color: Colors.redAccent, size: 18),
                  label: const Text(
                    "Limpiar Filtros",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? baseColor : baseColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? baseColor : Colors.transparent),
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