class UnidadItem {
  final int id;
  final String nombre;

  UnidadItem({required this.id, required this.nombre});

  factory UnidadItem.fromJson(Map<String, dynamic> json) {
    return UnidadItem(
      id: json['id'],
      nombre: json['nombre'] ?? 'Sin nombre',
    );
  }
}

class CargoItem {
  final int id;
  final String nombre;
  final int unidadId; // Clave para relacionarlo con la Unidad

  CargoItem({required this.id, required this.nombre, required this.unidadId});

  factory CargoItem.fromJson(Map<String, dynamic> json) {
    return CargoItem(
      id: json['id'],
      nombre: json['nombre'] ?? 'Sin nombre',
      unidadId: json['unidadId'] ?? 0,
    );
  }
}