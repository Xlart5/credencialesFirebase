import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/models/employee_model.dart';
import '../../config/provider/employee_provider.dart';

class ComputoItem {
  final Employee empleado;
  final String celular;
  bool tieneAcceso;
  bool isSelected;

  ComputoItem({
    required this.empleado,
    required this.celular,
    this.tieneAcceso = false,
    this.isSelected = false,
  });
}

class ComputoDataSource extends DataTableSource {
  final BuildContext context;
  final List<ComputoItem> _allItems;
  final VoidCallback onStateChanged;

  bool _showOnlyPending = false;
  String _searchQuery = '';
  String? _selectedUnidad;
  String? _selectedCargo; // 🔥 NUEVO: Filtro de cargo
  bool? _selectedAcceso;

  ComputoDataSource(this.context, this._allItems, this.onStateChanged);

  void updateData(List<Employee> newEmployees) {
    bool isDifferent = false;
    if (newEmployees.length != _allItems.length) {
      isDifferent = true;
    } else {
      for (int i = 0; i < newEmployees.length; i++) {
        if (newEmployees[i].id != _allItems[i].empleado.id ||
            newEmployees[i].accesoComputo != _allItems[i].tieneAcceso) {
          isDifferent = true;
          break;
        }
      }
    }

    if (isDifferent) {
      final selectedIds = _allItems
          .where((i) => i.isSelected)
          .map((i) => i.empleado.id)
          .toSet();
      _allItems.clear();

      for (var emp in newEmployees) {
        _allItems.add(
          ComputoItem(
            empleado: emp,
            celular: emp.celular,
            tieneAcceso: emp.accesoComputo,
            isSelected: selectedIds.contains(emp.id),
          ),
        );
      }

      Future.microtask(() {
        notifyListeners();
        onStateChanged();
      });
    }
  }

  void setPendingFilter(bool showOnlyPending) {
    _showOnlyPending = showOnlyPending;
    _clearSelections();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _clearSelections();
  }

  // 🔥 NUEVO: Recibe unidad y cargo al mismo tiempo
  void setUnidadYCargoFilter(String? unidad, String? cargo) {
    _selectedUnidad = unidad;
    _selectedCargo = cargo;
    _clearSelections();
  }

  void setAccesoFilter(bool? acceso) {
    _selectedAcceso = acceso;
    _clearSelections();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _selectedUnidad = null;
    _selectedCargo = null; // 🔥 Se limpia
    _selectedAcceso = null;
    _showOnlyPending = false;
    _clearSelections();
  }

  void _clearSelections() {
    for (var item in _allItems) {
      item.isSelected = false;
    }
    notifyListeners();
    onStateChanged();
  }

  List<ComputoItem> get items {
    return _allItems.where((item) {
      final emp = item.empleado;
      if (_showOnlyPending && item.tieneAcceso) return false;
      
      // 🔥 Validación estricta de filtros
      if (_selectedUnidad != null && emp.unidad != _selectedUnidad) return false;
      if (_selectedCargo != null && emp.cargo != _selectedCargo) return false;
      
      if (_selectedAcceso != null && item.tieneAcceso != _selectedAcceso) return false;
      
      if (_searchQuery.isNotEmpty) {
        final matchesName = emp.nombreCompleto.toLowerCase().contains(
          _searchQuery,
        );
        final matchesCI = emp.ci.contains(_searchQuery);
        if (!matchesName && !matchesCI) return false;
      }
      return true;
    }).toList();
  }

  int get totalCount => _allItems.length;
  int get conAccesoCount => _allItems.where((e) => e.tieneAcceso).length;
  int get sinAccesoCount => _allItems.where((e) => !e.tieneAcceso).length;

  bool get hasSelection => items.any((item) => item.isSelected);
  int get selectedCount => items.where((item) => item.isSelected).length;

  Future<bool> darAccesoMasivo() async {
    final seleccionados = items.where((item) => item.isSelected).toList();
    if (seleccionados.isEmpty) return false;

    final ids = seleccionados.map((i) => i.empleado.id).toList();
    final provider = context.read<EmployeeProvider>();
    final success = await provider.habilitarComputoMasivo(ids);

    if (success) {
      for (var item in seleccionados) {
        item.tieneAcceso = true;
        item.isSelected = false;
      }
      notifyListeners();
      onStateChanged();
      return true;
    }
    return false;
  }

  @override
  DataRow? getRow(int index) {
    final currentItems = items;
    if (index >= currentItems.length) return null;

    final item = currentItems[index];
    final emp = item.empleado;

    return DataRow(
      selected: item.isSelected,
      onSelectChanged: (bool? value) {
        if (value != null) {
          item.isSelected = value;
          notifyListeners();
          onStateChanged();
        }
      },
      cells: [
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  radius: 18,
                  child: const Icon(
                    Icons.person,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        emp.nombreCompleto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        emp.cargo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Text(
            emp.ci,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              emp.unidad,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            item.celular,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        DataCell(
          Icon(
            item.tieneAcceso
                ? Icons.check_circle_outline
                : Icons.do_not_disturb_alt,
            color: item.tieneAcceso ? Colors.green : Colors.red.shade300,
            size: 22,
          ),
        ),
        DataCell(
          Switch(
            value: item.tieneAcceso,
            activeColor: Colors.teal,
            inactiveTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.white,
            onChanged: (bool newValue) async {
              item.tieneAcceso = newValue;
              notifyListeners();
              onStateChanged();

              final provider = context.read<EmployeeProvider>();
              final success = await provider.cambiarAccesoComputo(
                emp.id,
                newValue,
              );

              if (!success) {
                item.tieneAcceso = !newValue;
                notifyListeners();
                onStateChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Error de conexión. No se pudo cambiar el estado.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => items.length;
  @override
  int get selectedRowCount => selectedCount;
}