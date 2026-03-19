import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _todosLosAccesos = [];

  // Listas para los filtros dinámicos
  List<String> _unidadesDisponibles = [];
  Map<String, List<String>> _cargosPorUnidad = {};

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get todosLosAccesos => _todosLosAccesos;
  List<String> get unidadesDisponibles => _unidadesDisponibles;
  Map<String, List<String>> get cargosPorUnidad => _cargosPorUnidad;

  Future<void> cargarHistorialCompleto() async {
    _isLoading = true;
    notifyListeners();

    try {
      final extSnapshot = await FirebaseFirestore.instance.collection('accesos_externos').get();
      final evtSnapshot = await FirebaseFirestore.instance.collection('accesos_eventuales').get();

      List<Map<String, dynamic>> listaTemporal = [];
      Set<String> unidadesSet = {};
      Map<String, Set<String>> cargosMap = {};

      void procesarDocumento(QueryDocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        String tipo = data['tipo'] ?? 'DESCONOCIDO';
        String unidad = data['unidad'] ?? '';
        String cargo = data['cargo'] ?? '';

        listaTemporal.add({
          'id': doc.id,
          'nombreCompleto': data['nombreCompleto'] ?? 'Sin Nombre',
          'tipo': tipo,
          'unidad': unidad,
          'cargo': cargo,
          'estaAdentro': data['estaAdentro'] ?? false,
          'historialAccesos': (data['historialAccesos'] as List<dynamic>?)?.map((acceso) {
            if (acceso is Map<String, dynamic>) {
              return {
                'tipo': acceso['tipo'] ?? '',
                'timestamp': acceso['timestamp'] ?? 0, 
                'fecha': acceso['fecha'] ?? '---',
                'hora': acceso['hora'] ?? '---',
              };
            }
            return <String, dynamic>{};
          }).toList() ?? [],
        });

        // Llenar datos dinámicos para el filtro de Eventuales
        if (tipo == 'EVENTUAL' && unidad.isNotEmpty && cargo.isNotEmpty) {
          unidadesSet.add(unidad);
          if (!cargosMap.containsKey(unidad)) cargosMap[unidad] = {};
          cargosMap[unidad]!.add(cargo);
        }
      }

      for (var doc in extSnapshot.docs) procesarDocumento(doc);
      for (var doc in evtSnapshot.docs) procesarDocumento(doc);

      _todosLosAccesos = listaTemporal;
      
      // Convertir Sets a Lists para los Dropdowns
      _unidadesDisponibles = unidadesSet.toList()..sort();
      _cargosPorUnidad = cargosMap.map((k, v) => MapEntry(k, v.toList()..sort()));

    } catch (e) {
      print("❌ Error al cargar historial: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}