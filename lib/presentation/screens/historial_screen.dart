import 'package:carnetizacion/config/helpers/reporte_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/provider/historial_provider.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  String _searchQuery = '';
  
  String _categoriaPrincipal = 'TODOS';
  
  String _tipoExterno = 'TODOS';
  final List<String> _tiposExternosDisponibles = ['TODOS', 'PRENSA', 'OBSERVADOR', 'DELEGADO', 'CANDIDATO', 'PUBLICO GENERAL'];
  
  String _partidoSeleccionado = 'TODOS';
  String _asociacionSeleccionada = 'TODAS';

  String _unidadSeleccionada = 'TODAS';
  String _cargoSeleccionado = 'TODOS';

  String _fechaSeleccionada = 'TODAS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistorialProvider>().cargarHistorialCompleto();
    });
  }

  Color _getColorPorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'CANDIDATO': return Colors.lightBlue;
      case 'DELEGADO': return Colors.blueAccent;
      case 'OBSERVADOR': return Colors.deepPurpleAccent;
      case 'PRENSA': return Colors.teal;
      case 'EVENTUAL': return Colors.orange;
      default: return Colors.blueGrey;
    }
  }

  void _mostrarDetallesHistorial(BuildContext context, Map<String, dynamic> persona) {
    List<dynamic> accesosRaw = persona['historialAccesos'] ?? [];
    accesosRaw.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    List<Map<String, dynamic>> pares = [];
    Map<String, dynamic>? entradaPendiente;

    for (var acc in accesosRaw) {
      if (acc['tipo'] == 'entrada') {
        entradaPendiente = acc;
      } else if (acc['tipo'] == 'salida' && entradaPendiente != null) {
        pares.add({'entrada': entradaPendiente, 'salida': acc});
        entradaPendiente = null;
      } else if (acc['tipo'] == 'salida' && entradaPendiente == null) {
        pares.add({'entrada': null, 'salida': acc});
      }
    }
    if (entradaPendiente != null) {
      pares.add({'entrada': entradaPendiente, 'salida': null});
    }

    pares = pares.reversed.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2B5E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.amber, size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona['nombreCompleto'] ?? 'Desconocido',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Rol: ${persona['tipo']} | Recinto: ${persona['recinto'] ?? 'N/A'}", 
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: pares.isEmpty
                  ? const Center(child: Text("No hay registros de acceso."))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: pares.length,
                      separatorBuilder: (_, __) => const Divider(height: 30),
                      itemBuilder: (ctx, index) {
                        final par = pares[index];
                        final entrada = par['entrada'];
                        final salida = par['salida'];

                        return Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Text("INGRESO", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 5),
                                  Text(entrada != null ? entrada['fecha'] : "---", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(entrada != null ? entrada['hora'] : "Sin registro", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 5),
                                  Text(entrada != null ? "📍 ${entrada['recinto'] ?? 'N/A'}" : "", style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_outlined, color: Colors.grey),
                              Column(
                                children: [
                                  const Text("SALIDA", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 5),
                                  Text(salida != null ? salida['fecha'] : "---", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(salida != null ? salida['hora'] : "Sigue Adentro", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 5),
                                  Text(salida != null ? "📍 ${salida['recinto'] ?? 'N/A'}" : "", style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistorialProvider>();

    List<Map<String, dynamic>> listaFiltrada = provider.todosLosAccesos.where((p) {
      if (_searchQuery.isNotEmpty && !(p['nombreCompleto']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)) {
        return false;
      }

      // 🔥 FILTRO POR FECHA LÓGICA
      if (_fechaSeleccionada != 'TODAS') {
        List<dynamic> accesos = p['historialAccesos'] ?? [];
        bool tieneAccesoEnFecha = accesos.any((acc) => acc['fechaLogica'] == _fechaSeleccionada);
        if (!tieneAccesoEnFecha) return false;
      }

      String tipoPersona = p['tipo']?.toString().toUpperCase() ?? '';

      if (_categoriaPrincipal == 'EXTERNOS') {
        if (tipoPersona == 'EVENTUAL') return false;
        if (_tipoExterno != 'TODOS' && tipoPersona != _tipoExterno) return false;
        
        if ((_tipoExterno == 'DELEGADO' || _tipoExterno == 'CANDIDATO') && _partidoSeleccionado != 'TODOS') {
          if ((p['partidoPolitico'] ?? '') != _partidoSeleccionado) return false;
        }
        
        if (_tipoExterno == 'OBSERVADOR' && _asociacionSeleccionada != 'TODAS') {
          if ((p['asociacion'] ?? '') != _asociacionSeleccionada) return false;
        }
      } 
      else if (_categoriaPrincipal == 'EVENTUALES') {
        if (tipoPersona != 'EVENTUAL') return false;
        String unidadPer = p['unidad']?.toString() ?? '';
        String cargoPer = p['cargo']?.toString() ?? '';

        if (_unidadSeleccionada != 'TODAS' && unidadPer != _unidadSeleccionada) return false;
        if (_cargoSeleccionado != 'TODOS' && cargoPer != _cargoSeleccionado) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go("/")),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Auditoría", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    SizedBox(height: 5),
                    Text("HISTORIAL DE ACCESOS", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    String tituloFiltro = _categoriaPrincipal;
                    if (_categoriaPrincipal == 'EXTERNOS') {
                      tituloFiltro += " - $_tipoExterno";
                      if (_partidoSeleccionado != 'TODOS') tituloFiltro += " ($_partidoSeleccionado)";
                      if (_asociacionSeleccionada != 'TODAS') tituloFiltro += " ($_asociacionSeleccionada)";
                    }
                    if (_categoriaPrincipal == 'EVENTUALES') tituloFiltro += " - $_unidadSeleccionada ($_cargoSeleccionado)";
                    
                    if (_fechaSeleccionada != 'TODAS') tituloFiltro += " | Jornada Lógica: $_fechaSeleccionada";
                    
                    ReportePdfService.generarReporteAccesos(listaFiltrada, tituloFiltro, _fechaSeleccionada);
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text("Exportar PDF"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: () => provider.cargarHistorialCompleto(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Recargar"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2B5E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: "Buscar por nombre...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  MenuBar(
                    style: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.grey.shade50),
                      elevation: WidgetStateProperty.all(0),
                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    children: [
                      SubmenuButton(
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () => setState(() => _fechaSeleccionada = 'TODAS'),
                            child: const Text('Todas las Jornadas', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const PopupMenuDivider(),
                          ...provider.fechasDisponibles.map((f) => MenuItemButton(
                            onPressed: () => setState(() => _fechaSeleccionada = f),
                            child: Text(f),
                          )).toList(),
                        ],
                        child: Text(
                          _fechaSeleccionada == 'TODAS' ? 'Jornada: TODAS' : 'Jornada: $_fechaSeleccionada',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ),
                      
                      SubmenuButton(
                        menuChildren: [
                          MenuItemButton(
                            child: const Text('Mostrar TODOS'),
                            onPressed: () => setState(() => _categoriaPrincipal = 'TODOS'),
                          ),
                          MenuItemButton(
                            child: const Text('Mostrar EXTERNOS'),
                            onPressed: () => setState(() { 
                              _categoriaPrincipal = 'EXTERNOS'; 
                              _tipoExterno = 'TODOS'; 
                              _partidoSeleccionado = 'TODOS';
                              _asociacionSeleccionada = 'TODAS';
                            }),
                          ),
                          MenuItemButton(
                            child: const Text('Mostrar EVENTUALES'),
                            onPressed: () => setState(() { 
                              _categoriaPrincipal = 'EVENTUALES'; 
                              _unidadSeleccionada = 'TODAS'; 
                              _cargoSeleccionado = 'TODOS'; 
                            }),
                          ),
                        ],
                        child: Text(
                          'Categoría: $_categoriaPrincipal', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2B5E)),
                        ),
                      ),

                      if (_categoriaPrincipal == 'EXTERNOS')
                        SubmenuButton(
                          menuChildren: _tiposExternosDisponibles.map((t) => MenuItemButton(
                            child: Text(t),
                            onPressed: () => setState(() { 
                              _tipoExterno = t; 
                              _partidoSeleccionado = 'TODOS'; 
                              _asociacionSeleccionada = 'TODAS';
                            }),
                          )).toList(),
                          child: Text(
                            'Filtro: $_tipoExterno',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ),

                      if (_categoriaPrincipal == 'EXTERNOS' && (_tipoExterno == 'DELEGADO' || _tipoExterno == 'CANDIDATO'))
                        SubmenuButton(
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () => setState(() => _partidoSeleccionado = 'TODOS'),
                              child: const Text('Todos los Partidos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            ),
                            const PopupMenuDivider(),
                            ...provider.partidosDisponibles.map((partido) => MenuItemButton(
                              onPressed: () => setState(() => _partidoSeleccionado = partido),
                              child: Text(partido),
                            )).toList(),
                          ],
                          child: Text(
                            _partidoSeleccionado == 'TODOS' ? 'Partido Político' : 'Partido: $_partidoSeleccionado',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                        ),

                      if (_categoriaPrincipal == 'EXTERNOS' && _tipoExterno == 'OBSERVADOR')
                        SubmenuButton(
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () => setState(() => _asociacionSeleccionada = 'TODAS'),
                              child: const Text('Todas las Organizaciones', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                            ),
                            const PopupMenuDivider(),
                            ...provider.asociacionesDisponibles.map((asoc) => MenuItemButton(
                              onPressed: () => setState(() => _asociacionSeleccionada = asoc),
                              child: Text(asoc),
                            )).toList(),
                          ],
                          child: Text(
                            _asociacionSeleccionada == 'TODAS' ? 'Organización' : 'Org: $_asociacionSeleccionada',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                          ),
                        ),

                      if (_categoriaPrincipal == 'EVENTUALES')
                        SubmenuButton(
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () => setState(() { _unidadSeleccionada = 'TODAS'; _cargoSeleccionado = 'TODOS'; }),
                              child: const Text('Todas las Unidades', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const PopupMenuDivider(),
                            ...provider.unidadesDisponibles.map((unidad) {
                              return SubmenuButton(
                                menuChildren: [
                                  MenuItemButton(
                                    onPressed: () => setState(() { _unidadSeleccionada = unidad; _cargoSeleccionado = 'TODOS'; }),
                                    child: const Text('Todos los Cargos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ),
                                  ...(provider.cargosPorUnidad[unidad] ?? []).map((cargo) {
                                    return MenuItemButton(
                                      onPressed: () => setState(() { _unidadSeleccionada = unidad; _cargoSeleccionado = cargo; }),
                                      child: Text(cargo),
                                    );
                                  }).toList(),
                                ],
                                child: Text(unidad),
                              );
                            }).toList(),
                          ],
                          child: Text(
                            _unidadSeleccionada == 'TODAS' 
                                ? 'Filtro: TODAS LAS UNIDADES' 
                                : 'Unidad: $_unidadSeleccionada ${_cargoSeleccionado != 'TODOS' ? '-> $_cargoSeleccionado' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: const [
                  Expanded(flex: 3, child: Text("Nombre Completo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  Expanded(flex: 2, child: Text("Rol / Tipo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  Expanded(flex: 2, child: Text("Recinto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))), 
                  Expanded(flex: 2, child: Text("Estado Actual", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  Expanded(flex: 1, child: Center(child: Text("Acción", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))),
                ],
              ),
            ),
            const Divider(),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        final persona = listaFiltrada[index];
                        bool estaAdentro = persona['estaAdentro'] == true;
                        String rol = persona['tipo'] ?? 'N/A';
                        Color colorRol = _getColorPorRol(rol);
                        
                        String detalleExtra = "";
                        if (rol == 'DELEGADO' || rol == 'CANDIDATO') detalleExtra = persona['partidoPolitico'] ?? '';
                        if (rol == 'OBSERVADOR') detalleExtra = persona['asociacion'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(persona['nombreCompleto'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    if (detalleExtra.isNotEmpty)
                                      Text(detalleExtra, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: colorRol.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                    child: Text(rol, style: TextStyle(color: colorRol, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    const Icon(Icons.business, size: 16, color: Colors.blueGrey),
                                    const SizedBox(width: 5),
                                    Text(persona['recinto'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(estaAdentro ? Icons.login : Icons.logout, size: 18, color: estaAdentro ? Colors.green : Colors.red),
                                    const SizedBox(width: 8),
                                    Text(estaAdentro ? "Adentro" : "Afuera", style: TextStyle(color: estaAdentro ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: ElevatedButton(
                                    onPressed: () => _mostrarDetallesHistorial(context, persona),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade100,
                                      foregroundColor: Colors.amber.shade900,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text("Ver Historial", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}