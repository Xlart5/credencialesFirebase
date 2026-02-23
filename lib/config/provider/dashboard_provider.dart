import 'package:flutter/material.dart';

// Modelo de Empleado
class Employee {
  final String id;
  final String name;
  final String role;
  final String ci;
  final String unit;
  final String status; // 'Impreso', 'Pendiente', 'Error'

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.ci,
    required this.unit,
    required this.status,
  });
}

// Gestor de Estado
class DashboardProvider extends ChangeNotifier {
  // Datos Mock (Simulados de la imagen)
  final List<Employee> _employees = [
    Employee(
      id: '1',
      name: 'Carlos Mendizábal',
      role: 'Analista Programador',
      ci: '8342191 - LP',
      unit: 'TECNOLOGÍAS',
      status: 'Impreso',
    ),
    Employee(
      id: '2',
      name: 'Ana María Rojas',
      role: 'Jefe de Unidad',
      ci: '4910238 - OR',
      unit: 'RR.HH.',
      status: 'Pendiente',
    ),
    Employee(
      id: '3',
      name: 'Roberto Vaca',
      role: 'Auxiliar Administrativo',
      ci: '1029384 - SC',
      unit: 'ADMINISTRACIÓN',
      status: 'Impreso',
    ),
  ];

  String _searchQuery = '';

  List<Employee> get employees {
    if (_searchQuery.isEmpty) return _employees;
    return _employees
        .where(
          (e) =>
              e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.ci.contains(_searchQuery),
        )
        .toList();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Métodos simulados de acción
  void deleteEmployee(String id) {
    _employees.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
