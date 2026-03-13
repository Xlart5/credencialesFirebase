import 'package:cloud_firestore/cloud_firestore.dart';

class PersonaExterna {
  final String qrId; // Este será el ID del documento (Ej. EXT-PRENSA-827364)
  final String nombreCompleto;
  final String ci;
  final String celular;
  final String tipo; // PRENSA, OBSERVADOR, DELEGADO, etc.
  final DateTime? horaEntrada;
  final DateTime? horaSalida;
  final bool estaAdentro; // Para saber si el próximo escaneo es salida

  PersonaExterna({
    required this.qrId,
    required this.nombreCompleto,
    required this.ci,
    required this.celular,
    required this.tipo,
    this.horaEntrada,
    this.horaSalida,
    required this.estaAdentro,
  });

  factory PersonaExterna.fromFirestore(Map<String, dynamic> json, String id) {
    return PersonaExterna(
      qrId: id,
      nombreCompleto: json['nombreCompleto'] ?? '',
      ci: json['ci'] ?? '',
      celular: json['celular'] ?? '',
      tipo: json['tipo'] ?? 'GENERAL',
      horaEntrada: json['horaEntrada'] != null
          ? (json['horaEntrada'] as Timestamp).toDate()
          : null,
      horaSalida: json['horaSalida'] != null
          ? (json['horaSalida'] as Timestamp).toDate()
          : null,
      estaAdentro: json['estaAdentro'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombreCompleto': nombreCompleto,
      'ci': ci,
      'celular': celular,
      'tipo': tipo,
      'horaEntrada': horaEntrada,
      'horaSalida': horaSalida,
      'estaAdentro': estaAdentro,
    };
  }
}
