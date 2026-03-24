import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _todosLosAccesos = [];

  List<String> _unidadesDisponibles = [];
  Map<String, List<String>> _cargosPorUnidad = {};
  
  List<String> _partidosDisponibles = [];
  List<String> _asociacionesDisponibles = [];
  
  List<String> _fechasDisponibles = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get todosLosAccesos => _todosLosAccesos;
  List<String> get unidadesDisponibles => _unidadesDisponibles;
  Map<String, List<String>> get cargosPorUnidad => _cargosPorUnidad;
  List<String> get partidosDisponibles => _partidosDisponibles;
  List<String> get asociacionesDisponibles => _asociacionesDisponibles;
  List<String> get fechasDisponibles => _fechasDisponibles;

  Future<void> cargarHistorialCompleto() async {
    _isLoading = true;
    notifyListeners();

    try {
      final extSnapshot = await FirebaseFirestore.instance.collection('accesos_externos').get();
      final evtSnapshot = await FirebaseFirestore.instance.collection('accesos_eventuales').get();

      List<Map<String, dynamic>> listaTemporal = [];
      Set<String> unidadesSet = {};
      Map<String, Set<String>> cargosMap = {};
      Set<String> partidosSet = {};
      Set<String> asociacionesSet = {};
      Set<String> fechasSet = {};

      void procesarDocumento(QueryDocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        String tipo = data['tipo'] ?? 'DESCONOCIDO';
        String unidad = data['unidad'] ?? '';
        String cargo = data['cargo'] ?? '';
        String partido = data['partidoPolitico']?.toString().toUpperCase() ?? '';
        String asociacion = data['asociacion']?.toString().toUpperCase() ?? '';

        String recinto = (tipo == 'EVENTUAL') ? 'CÓMPUTO' : 'CDL';

        listaTemporal.add({
          'id': doc.id,
          'nombreCompleto': data['nombreCompleto'] ?? 'Sin Nombre',
          'tipo': tipo,
          'unidad': unidad,
          'cargo': cargo,
          'partidoPolitico': partido, 
          'asociacion': asociacion,   
          'recinto': recinto,
          'estaAdentro': data['estaAdentro'] ?? false,
          'historialAccesos': (data['historialAccesos'] as List<dynamic>?)?.map((acceso) {
            if (acceso is Map<String, dynamic>) {
              
              // 🔥 MAGIA DE LA JORNADA LÓGICA (7AM a 6:59AM)
              int ts = acceso['timestamp'] ?? 0;
              String fechaLogica = '---';
              if (ts > 0) {
                DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts);
                // Si la hora es menor a 7 (0, 1, 2, 3, 4, 5, 6), pertenece al "día anterior"
                if (dt.hour < 7) {
                  dt = dt.subtract(const Duration(days: 1));
                }
                fechaLogica = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
              } else {
                fechaLogica = acceso['fecha'] ?? '---';
              }
              
              if (fechaLogica != '---') fechasSet.add(fechaLogica);

              return {
                'tipo': acceso['tipo'] ?? '',
                'timestamp': ts, 
                'fecha': acceso['fecha'] ?? '---', // Para mostrar en pantalla
                'hora': acceso['hora'] ?? '---',
                'recinto': recinto,
                'fechaLogica': fechaLogica, // 🔥 Para filtrar (agrupado por jornada)
              };
            }
            return <String, dynamic>{};
          }).toList() ?? [],
        });

        if (tipo == 'EVENTUAL' && unidad.isNotEmpty && cargo.isNotEmpty) {
          unidadesSet.add(unidad);
          if (!cargosMap.containsKey(unidad)) cargosMap[unidad] = {};
          cargosMap[unidad]!.add(cargo);
        }
        
        if ((tipo == 'DELEGADO' || tipo == 'CANDIDATO') && partido.isNotEmpty) {
          partidosSet.add(partido);
        } else if (tipo == 'OBSERVADOR' && asociacion.isNotEmpty) {
          asociacionesSet.add(asociacion);
        }
      }

      for (var doc in extSnapshot.docs) procesarDocumento(doc);
      for (var doc in evtSnapshot.docs) procesarDocumento(doc);

      _todosLosAccesos = listaTemporal;
      
      _unidadesDisponibles = unidadesSet.toList()..sort();
      _cargosPorUnidad = cargosMap.map((k, v) => MapEntry(k, v.toList()..sort()));
      _partidosDisponibles = partidosSet.toList()..sort();
      _asociacionesDisponibles = asociacionesSet.toList()..sort();
      
      // Ordenamos las fechas Lógicas
      _fechasDisponibles = fechasSet.toList()..sort((a, b) {
        // Simple fix para ordenar DD/MM/YYYY
        var pA = a.split('/'); var pB = b.split('/');
        if(pA.length == 3 && pB.length == 3) {
          return "${pB[2]}${pB[1]}${pB[0]}".compareTo("${pA[2]}${pA[1]}${pA[0]}");
        }
        return b.compareTo(a);
      });

    } catch (e) {
      print("❌ Error al cargar historial: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}