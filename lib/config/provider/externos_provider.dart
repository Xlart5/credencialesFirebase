import 'dart:math';
import 'package:carnetizacion/config/models/externos_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExternosProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Lista para mostrar la tabla de control del día del evento
  List<PersonaExterna> _registrosDia = [];
  List<PersonaExterna> get registrosDia => _registrosDia;

  // =======================================================
  // 1. GENERADOR DE LOTES DE QR VACÍOS (Para pre-impresión)
  // =======================================================
  List<String> generarLoteQRs(String tipo, int cantidad) {
    List<String> lote = [];
    final random = Random();

    // Convertimos el tipo a un formato corto (Ej. Prensa -> PRENSA)
    String prefijo = tipo.toUpperCase().replaceAll(' ', '');

    for (int i = 0; i < cantidad; i++) {
      // Genera un número aleatorio de 6 dígitos
      String numRandom = (100000 + random.nextInt(900000)).toString();
      lote.add("EXT-$prefijo-$numRandom");
    }

    return lote; // Esta lista se enviará a tu generador de PDFs después
  }

  // =======================================================
  // 2. LÓGICA PRINCIPAL DE ESCANEO (El Guardia)
  // =======================================================
  // Esta función devolverá:
  // "NUEVO" -> Hay que registrarlo
  // "ENTRADA" -> Entró al recinto
  // "SALIDA" -> Salió del recinto
  // "ERROR" -> QR inválido
  Future<String> procesarEscaneoQR(String qrCode) async {
    // Validar que sea un QR de nuestro sistema (EXT-TIPO-NUMERO)
    if (!qrCode.startsWith("EXT-")) return "ERROR";

    try {
      _isLoading = true;
      notifyListeners();

      // Buscamos si el QR ya tiene dueño en la base de datos
      DocumentSnapshot doc = await _db
          .collection('accesos_externos')
          .doc(qrCode)
          .get();

      if (!doc.exists) {
        // EL QR ESTÁ VIRGEN -> Mandamos a la pantalla de registro
        _isLoading = false;
        notifyListeners();
        return "NUEVO";
      }

      // EL QR YA TIENE DUEÑO -> Registramos Entrada o Salida
      PersonaExterna persona = PersonaExterna.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      if (persona.estaAdentro) {
        // Si estaba adentro, significa que está saliendo
        await _db.collection('accesos_externos').doc(qrCode).update({
          'estaAdentro': false,
          'horaSalida': FieldValue.serverTimestamp(),
        });
        _isLoading = false;
        notifyListeners();
        return "SALIDA";
      } else {
        // Si estaba afuera, significa que está entrando
        await _db.collection('accesos_externos').doc(qrCode).update({
          'estaAdentro': true,
          // Solo actualizamos la hora de entrada si es la primera vez que entra o si quieres sobrescribirla
          'horaEntrada': FieldValue.serverTimestamp(),
        });
        _isLoading = false;
        notifyListeners();
        return "ENTRADA";
      }
    } catch (e) {
      print("Error escaneando: $e");
      _isLoading = false;
      notifyListeners();
      return "ERROR";
    }
  }

  // =======================================================
  // 3. REGISTRAR A LA PERSONA (Cuando el QR es nuevo)
  // =======================================================
  Future<bool> registrarPersonaNueva({
    required String qrId,
    required String nombre,
    required String ci,
    required String telefono,
  }) async {
    try {
      // Extraemos el TIPO del mismo QR (Ej. EXT-PRENSA-123456 -> Extrae PRENSA)
      List<String> partes = qrId.split('-');
      String tipoAsignado = partes.length >= 2 ? partes[1] : "GENERAL";

      await _db.collection('accesos_externos').doc(qrId).set({
        'nombreCompleto': nombre.toUpperCase(),
        'ci': ci,
        'celular': telefono,
        'tipo': tipoAsignado,
        'estaAdentro':
            true, // ¡Como lo estamos registrando en la puerta, entra directo!
        'horaEntrada': FieldValue.serverTimestamp(),
        'horaSalida': null,
      });

      return true;
    } catch (e) {
      print("Error registrando externo: $e");
      return false;
    }
  }

  // =======================================================
  // 4. ESCUCHAR TABLA DE ACCESOS (Tiempo real para PC Central)
  // =======================================================
  void escucharAccesosDelDia() {
    _db
        .collection('accesos_externos')
        .orderBy('horaEntrada', descending: true)
        .snapshots()
        .listen((snapshot) {
          _registrosDia = snapshot.docs
              .map((doc) => PersonaExterna.fromFirestore(doc.data(), doc.id))
              .toList();
          notifyListeners();
        });
  }
}
