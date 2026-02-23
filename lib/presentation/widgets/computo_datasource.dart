import 'package:flutter/material.dart';
import '../../config/models/employee_model.dart';

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
  final List<ComputoItem> _allItems; // Guardamos TODOS los registros aquí
  final VoidCallback
  onStateChanged; // Avisa a la pantalla para actualizar las tarjetas

  bool _showOnlyPending = false; // Estado del filtro

  ComputoDataSource(this.context, this._allItems, this.onStateChanged);

  // --- FILTRO ---
  void setFilter(bool showOnlyPending) {
    _showOnlyPending = showOnlyPending;
    // Limpiamos las selecciones al cambiar de filtro para evitar errores
    for (var item in _allItems) {
      item.isSelected = false;
    }
    notifyListeners();
    onStateChanged();
  }

  // Obtenemos solo los ítems que se deben mostrar según el filtro
  List<ComputoItem> get items {
    if (_showOnlyPending) {
      return _allItems.where((e) => !e.tieneAcceso).toList();
    }
    return _allItems;
  }

  // --- CONTADORES PARA LAS TARJETAS ---
  int get totalCount => _allItems.length;
  int get conAccesoCount => _allItems.where((e) => e.tieneAcceso).length;
  int get sinAccesoCount => _allItems.where((e) => !e.tieneAcceso).length;

  // --- LÓGICA DE SELECCIÓN ---
  bool get hasSelection => items.any((item) => item.isSelected);
  int get selectedCount => items.where((item) => item.isSelected).length;

  void darAccesoMasivo() {
    bool changed = false;
    // Solo damos acceso a los que están visibles en la tabla y seleccionados
    for (var item in items) {
      if (item.isSelected) {
        item.tieneAcceso = true;
        item.isSelected = false;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      onStateChanged();
    }
  }

  @override
  DataRow? getRow(int index) {
    final currentItems = items; // Usamos la lista filtrada
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
            onChanged: (bool value) {
              item.tieneAcceso = value;
              notifyListeners();
              onStateChanged(); // IMPORTANTE: Avisar a la pantalla para actualizar contadores
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => items.length; // Filas dependen del filtro
  @override
  int get selectedRowCount => selectedCount;
}
