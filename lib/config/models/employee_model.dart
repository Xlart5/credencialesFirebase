import 'package:flutter/material.dart';

class Employee {
  final int id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String carnetIdentidad;
  final String? correo;
  final String celular;
  final bool accesoComputo;
  final String estadoActual;
  final String cargo;
  final String unidad;
  final int ImageId;
  final String photoUrl;
  final String qrUrl;
  final String Circu;
  // 🔥 NUEVO CAMPO: Para distinguir Planta de Eventual
  final String tipo;

  Employee({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.carnetIdentidad,
    this.correo,
    required this.celular,
    required this.accesoComputo,
    required this.estadoActual,
    required this.cargo,
    required this.unidad,
    required this.photoUrl,
    required this.qrUrl,
    required this.Circu,
    required this.ImageId,
    this.tipo = 'EVENTUAL',  // Valor por defecto
  });

  String get nombreCompleto =>
      "$nombre $apellidoPaterno $apellidoMaterno".trim();
  String get ci => carnetIdentidad;
  int get estado => estadoActual.toUpperCase() == "PERSONAL REGISTRADO" ? 0 : 1;

  // LÓGICA DE COLORES
  Color get colorEstado {
    final estadoUpper = estadoActual.toUpperCase();
    if (estadoUpper == "PERSONAL REGISTRADO") {
      return Colors.redAccent;
    } else if (estadoUpper.contains("RENUNCIA")) {
      return Colors.orangeAccent;
    } else if (estadoUpper == "CREDENCIAL DEVUELTO") {
      return Colors.blueAccent;
    } else if (estadoUpper == "CONTRATO TERMINADO") {
      return Colors.grey;
    } else {
      return Colors.greenAccent.shade700;
    }
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellidoPaterno: json['apellidoPaterno'] ?? '',
      apellidoMaterno: json['apellidoMaterno'] ?? '',
      carnetIdentidad: json['carnetIdentidad'] ?? '',
      correo: json['correo'] ?? 'sin correo',
      celular: json['celular'] ?? '',
      accesoComputo: json['accesoComputo'] ?? false,
      estadoActual: json['estadoActual'] ?? 'DESCONOCIDO',
      cargo: json['cargo'] ?? 'Sin Cargo',
      unidad: json['unidad'] ?? 'Sin Unidad',
      photoUrl: json['imagen'] ?? '',
      qrUrl: json['qr'] ?? '',
      Circu: json['nroCircunscripcion'] ?? 'Sin Circunscripción',
      ImageId: json['imagenId'] ?? 0,
      tipo: json['tipo'] ?? 'EVENTUAL', // Lo leemos del backend
    );
  }

  // 🔥 FUNCIÓN PARA LA CACHÉ: Permite guardar la lista fusionada en la memoria
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellidoPaterno': apellidoPaterno,
      'apellidoMaterno': apellidoMaterno,
      'carnetIdentidad': carnetIdentidad,
      'correo': correo,
      'celular': celular,
      'accesoComputo': accesoComputo,
      'estadoActual': estadoActual,
      'cargo': cargo,
      'unidad': unidad,
      'imagen': photoUrl,
      'qr': qrUrl,
      'nroCircunscripcion': Circu,
      'imagenId': ImageId,
      'tipo': tipo, // Lo guardamos en caché
    };
  }

  // 🔥 COPYWITH INTACTO
  Employee copyWith({
    int? id,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? carnetIdentidad,
    String? correo,
    String? celular,
    bool? accesoComputo,
    String? estadoActual,
    String? cargo,
    String? unidad,
    String? photoUrl,
    String? qrUrl,
    String? circuns,
    String? tipo, // Nuevo parámetro opcional
  }) {
    return Employee(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      carnetIdentidad: carnetIdentidad ?? this.carnetIdentidad,
      correo: correo ?? this.correo,
      celular: celular ?? this.celular,
      accesoComputo: accesoComputo ?? this.accesoComputo,
      estadoActual: estadoActual ?? this.estadoActual,
      cargo: cargo ?? this.cargo,
      unidad: unidad ?? this.unidad,
      photoUrl: photoUrl ?? this.photoUrl,
      qrUrl: qrUrl ?? this.qrUrl,
      Circu: circuns ?? this.Circu,
      ImageId: this.ImageId,
      tipo: tipo ?? this.tipo, // Asignamos el nuevo valor o mantenemos el actual
    );
  }

  // 🔥 ESTO ES VITAL PARA QUE LOS CHECKBOXES Y LA SELECCIÓN FUNCIONEN PERFECTO
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee && other.id == id; // Compara siempre por ID
  }

  @override
  int get hashCode => id.hashCode;
}