class UnidadModel {
  final int id;
  final String nombre;
  final String abreviatura;
  final bool estado;
  final int totalCargosProceso;

  UnidadModel({
    required this.id,
    required this.nombre,
    required this.abreviatura,
    required this.estado,
    required this.totalCargosProceso,
  });

  factory UnidadModel.fromJson(Map<String, dynamic> json) {
    return UnidadModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin Nombre',
      abreviatura: json['abreviatura'] ?? '',
      estado: json['estado'] ?? false,
      // Usaremos esto provisionalmente para "Cantidad de Empleados/Cargos"
      totalCargosProceso: json['totalCargosProceso'] ?? 0, 
    );
  }
}

class CargoUnidadModel {
  final int id;
  final String nombre;
  final int unidadId;
  final bool activo;

  CargoUnidadModel({
    required this.id,
    required this.nombre,
    required this.unidadId,
    required this.activo,
  });

  factory CargoUnidadModel.fromJson(Map<String, dynamic> json) {
    return CargoUnidadModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin Cargo',
      unidadId: json['unidadId'] ?? 0,
      activo: json['activo'] ?? true, // Por defecto true si viene null
    );
  }
}