import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import 'computo_datasource.dart';

class ComputoSidebar extends StatefulWidget {
  final ComputoDataSource dataSource;
  final Set<String> unidades;
  final Map<String, int> conteoUnidades;

  const ComputoSidebar({
    super.key,
    required this.dataSource,
    required this.unidades,
    required this.conteoUnidades,
  });

  @override
  State<ComputoSidebar> createState() => _ComputoSidebarState();
}

class _ComputoSidebarState extends State<ComputoSidebar> {
  String? _selectedUnidad;
  bool? _selectedAcceso; // null = Todos, true = Con Acceso, false = Sin Acceso

  void _onUnidadTapped(String unidad) {
    setState(() {
      _selectedUnidad = _selectedUnidad == unidad ? null : unidad;
      widget.dataSource.setUnidadFilter(_selectedUnidad);
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
      _selectedAcceso = null;
      widget.dataSource.clearAllFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
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

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: widget.unidades.map((unidad) {
                  final isSelected = _selectedUnidad == unidad;
                  final count = widget.conteoUnidades[unidad] ?? 0;

                  return _buildUnidadItem(
                    title: unidad,
                    count: count,
                    isSelected: isSelected,
                    onTap: () => _onUnidadTapped(unidad),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. 🔥 NUEVA SECCIÓN: ACCESO A CÓMPUTO
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

          // 4. BOTÓN LIMPIAR
          if (_selectedUnidad != null || _selectedAcceso != null)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _clearFilters,
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
