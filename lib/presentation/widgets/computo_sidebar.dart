import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import 'computo_datasource.dart';

class ComputoSidebar extends StatefulWidget {
  final ComputoDataSource dataSource;
  final Set<String> unidades;
  final Map<String, List<String>> cargosPorUnidad; // 🔥 Recibe el mapa

  const ComputoSidebar({
    super.key,
    required this.dataSource,
    required this.unidades,
    required this.cargosPorUnidad,
  });

  @override
  State<ComputoSidebar> createState() => _ComputoSidebarState();
}

class _ComputoSidebarState extends State<ComputoSidebar> {
  String? _selectedUnidad;
  String? _selectedCargo;
  bool? _selectedAcceso; 
  final MenuController _menuController = MenuController();

  void _onUnidadYCargoTapped(String? unidad, String? cargo) {
    setState(() {
      _selectedUnidad = unidad;
      _selectedCargo = cargo;
      widget.dataSource.setUnidadYCargoFilter(unidad, cargo);
    });
  }

  void _onAccesoTapped(bool acceso) {
    setState(() {
      _selectedAcceso = _selectedAcceso == acceso ? null : acceso;
      widget.dataSource.setAccesoFilter(_selectedAcceso);
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedUnidad = null;
      _selectedCargo = null;
      _selectedAcceso = null;
      widget.dataSource.clearAllFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 ESTILOS MODERNOS (Los mismos que usamos en el Dashboard)
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

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 20),
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

          const Text(
            "UNIDAD Y CARGO",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),

          // 🔥 MENÚ DE HOVER MODERNO
          MouseRegion(
            onEnter: (_) {
              if (!_menuController.isOpen) {
                _menuController.open();
              }
            },
            child: MenuAnchor(
              controller: _menuController,
              style: modernMenuStyle,
              menuChildren: [
                MenuItemButton(
                  style: modernItemStyle,
                  onPressed: () => _onUnidadYCargoTapped(null, null),
                  child: const Text('TODAS LAS UNIDADES', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                ),
                const PopupMenuDivider(),
                
                ...widget.unidades.map((unidad) {
                  return SubmenuButton(
                    menuStyle: modernMenuStyle,
                    style: modernItemStyle,
                    menuChildren: [
                      MenuItemButton(
                        style: modernItemStyle,
                        onPressed: () => _onUnidadYCargoTapped(unidad, null),
                        child: const Text('Todos los Cargos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ),
                      ...(widget.cargosPorUnidad[unidad] ?? []).map((cargo) {
                        return MenuItemButton(
                          style: modernItemStyle,
                          onPressed: () => _onUnidadYCargoTapped(unidad, cargo),
                          child: Text(cargo),
                        );
                      }).toList(),
                    ],
                    child: Text(unidad), 
                  );
                }).toList(),
              ],
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
                          _selectedUnidad == null
                              ? 'Seleccionar Unidad...'
                              : '$_selectedUnidad\n${_selectedCargo ?? 'Todos los cargos'}',
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

          const SizedBox(height: 25),

          const Text(
            "ACCESO A CÓMPUTO",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 15),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildAccesoChip(
                estado: "Con Acceso",
                isSelected: _selectedAcceso == true,
                baseColor: Colors.teal,
                onTap: () => _onAccesoTapped(true),
              ),
              _buildAccesoChip(
                estado: "Sin Acceso",
                isSelected: _selectedAcceso == false,
                baseColor: Colors.redAccent,
                onTap: () => _onAccesoTapped(false),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_selectedUnidad != null || _selectedAcceso != null || _selectedCargo != null)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _clearFilters,
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
    );
  }

  Widget _buildAccesoChip({
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