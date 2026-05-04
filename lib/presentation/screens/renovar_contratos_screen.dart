import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/models/employee_model.dart';
import '../../config/theme/app_colors.dart';
import '../widgets/sidebar_filter.dart';

// 🔥 IMPORTAMOS EL WIDGET DEL MODAL
import '../widgets/nuevo_contrato_dialog.dart';

class RenovarContratosScreen extends StatefulWidget {
  const RenovarContratosScreen({super.key});

  @override
  State<RenovarContratosScreen> createState() => _RenovarContratosScreenState();
}

class _RenovarContratosScreenState extends State<RenovarContratosScreen> {
  List<Employee> _candidatosParaRenovar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prepararCruceDeDatos();
  }

  // =========================================================
  // 🔥 LA LÓGICA DE CRUCE (FIREBASE vs ENDPOINT)
  // =========================================================
  Future<void> _prepararCruceDeDatos() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<EmployeeProvider>();
    
    // 1. Nos aseguramos de tener la lista más fresca del endpoint
    await provider.fetchPersonalActivo();
    provider.clearFilters();

    // 2. Descargamos todos los históricos de Firebase
    final personasFirebase = await provider.obtenerPersonasHistoricasFirebase();

    // 3. Extraemos solo los IDs de la gente que está activa actualmente en el endpoint
    final idsActivosEndpoint = provider.allEmployees.map((e) => e.id).toSet();

    // 4. Obtenemos el Rol para el filtro RBAC
    final prefs = await SharedPreferences.getInstance();
    String rol = prefs.getString('rol') ?? '';
    String miUnidad = prefs.getString('nombreUnidad') ?? '';

    List<Employee> listaCruzada = [];

    for (var p in personasFirebase) {
      int idFbase = p['idBackend'] ?? 0;
      String unidadHistorica = p['ultimaUnidad'] ?? 'Sin Unidad';

      // Validación de Seguridad (RBAC): Si es consulta, solo ve su unidad
      if (rol == 'CONSULTA' && unidadHistorica.trim().toLowerCase() != miUnidad.trim().toLowerCase()) {
        continue;
      }

      // 🔥 EL CRUCE MAGISTRAL: Si está en Firebase PERO NO está en el endpoint, es candidato a renovar
      if (!idsActivosEndpoint.contains(idFbase)) {
        listaCruzada.add(Employee(
          id: idFbase,
          nombre: p['nombreCompleto'] ?? 'Sin Nombre',
          apellidoPaterno: '',
          apellidoMaterno: '',
          carnetIdentidad: p['ci'] ?? '',
          correo: '',
          celular: '',
          accesoComputo: false,
          estadoActual: 'CONTRATO TERMINADO',
          cargo: p['ultimoCargo'] ?? 'Sin Cargo',
          unidad: unidadHistorica,
          photoUrl: '', 
          qrUrl: '', 
          Circu: '', 
          ImageId: 0,
          tipo: 'HISTORICO',
        ));
      }
    }

    if (mounted) {
      setState(() {
        _candidatosParaRenovar = listaCruzada;
        _isLoading = false;
      });
      // Le pasamos esta lista temporal al provider para que el SidebarFilter construya los menús
      provider.setEmpleadosHistoricosTemporales(_candidatosParaRenovar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    // =========================================================
    // 🔥 APLICAR FILTROS VISUALES (Barra lateral y Buscador)
    // =========================================================
    final listaFiltrada = _candidatosParaRenovar.where((emp) {
      if (provider.selectedUnidadFilter != null && emp.unidad != provider.selectedUnidadFilter) return false;
      if (provider.selectedCargoFilter != null && emp.cargo != provider.selectedCargoFilter) return false;

      if (provider.searchQuery.isNotEmpty) {
        final query = provider.searchQuery.toLowerCase();
        final matches = emp.ci.contains(query) || emp.nombreCompleto.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Renovación de Contratos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Refrescar datos",
            onPressed: _prepararCruceDeDatos,
          )
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarFilter(hideEstados: true),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.autorenew, color: Colors.blue, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        "Personal Libre para Nuevo Contrato",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                      const Spacer(),
                      
                      SizedBox(
                        width: 300,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Buscar por CI o Nombre...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          ),
                          onChanged: (val) => provider.search(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : listaFiltrada.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 15),
                                const Text(
                                  "No hay personal disponible para renovación en este filtro.",
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: listaFiltrada.length,
                            itemBuilder: (context, index) {
                              final emp = listaFiltrada[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey.shade400,
                                    child: const Icon(Icons.person_off, color: Colors.white, size: 28),
                                  ),
                                  title: Text(
                                    emp.nombreCompleto,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 16),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "CI: ${emp.ci}  •  Última Unidad: ${emp.unidad}\nÚltimo Cargo: ${emp.cargo}",
                                      style: TextStyle(height: 1.4, color: Colors.grey.shade700),
                                    ),
                                  ),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                    ),
                                    onPressed: () async {
                                      // 1. Abrimos el modal para elegir el nuevo cargo
                                      await showDialog(
                                        context: context,
                                        builder: (ctx) => NuevoContratoDialog(empleado: emp),
                                      );
                                      // 2. Al cerrar el modal, recargamos el cruce. 
                                      // Si se le dio contrato, el backend lo devolverá y desaparecerá de esta lista.
                                      _prepararCruceDeDatos();
                                    },
                                    icon: const Icon(Icons.add_task, size: 18),
                                    label: const Text("Iniciar Nuevo Contrato", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}