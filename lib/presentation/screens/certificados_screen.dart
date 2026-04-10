import 'package:carnetizacion/presentation/widgets/finalizar_contrato_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';
import '../widgets/side_menu.dart';
import '../widgets/sidebar_filter.dart';

// 🔥 IMPORTAMOS EL WIDGET PARA EL DIÁLOGO MASIVO
import '../widgets/cierre_masivo_dialog.dart';

class CertificadosScreen extends StatefulWidget {
  const CertificadosScreen({super.key});

  @override
  State<CertificadosScreen> createState() => _CertificadosScreenState();
}

class _CertificadosScreenState extends State<CertificadosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchPersonalActivo();
      context.read<EmployeeProvider>().clearFilters(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    // =========================================================
    // 🔥 LÓGICA DE FILTRADO ESTRICTO PARA CERTIFICADOS
    // =========================================================
    final listaFiltrada = provider.allEmployees.where((emp) {
      if (emp.estadoActual.toUpperCase() != 'CREDENCIAL DEVUELTO') return false;
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
        title: const Text(
          "Cierre de Contratos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryDark,
        actions: [
          // 🔥 NUEVO BOTÓN: CIERRE MASIVO
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CierreMasivoDialog(),
                );
              },
              icon: const Icon(Icons.event_busy, color: Colors.redAccent),
              label: const Text(
                "CIERRE MASIVO (POR CARGO)",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(backgroundColor: Colors.white10),
            ),
          ),
          
          // BOTÓN ORIGINAL: IMPRESIÓN MASIVA
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: () => context.push('/certificados-masivo'),
              icon: const Icon(Icons.collections_bookmark, color: Colors.white),
              label: const Text(
                "IMPRESIÓN MASIVA",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      drawer: const SideMenu(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/certificados-masivo'),
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.print, color: Colors.white),
        label: const Text(
          "IR A IMPRESIÓN MASIVA",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                      const Icon(Icons.assignment_turned_in, color: Colors.orange, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        "Personal con Credencial Devuelta",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                      const Spacer(),
                      
                      SizedBox(
                        width: 300,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Buscar por CI o Nombre...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
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
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : listaFiltrada.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 15),
                                const Text(
                                  "No hay personal pendiente de cierre en este filtro.",
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
                                  leading: const CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.orange,
                                    child: Icon(Icons.person, color: Colors.white, size: 28),
                                  ),
                                  title: Text(
                                    emp.nombreCompleto,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 16),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "CI: ${emp.ci}  •  Unidad: ${emp.unidad}\nCargo: ${emp.cargo}",
                                      style: TextStyle(height: 1.4, color: Colors.grey.shade700),
                                    ),
                                  ),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                    ),
                                    onPressed: () => showFinalizarContratoSheet(context, emp),
                                    icon: const Icon(Icons.block, size: 18),
                                    label: const Text(
                                      "Finalizar y Cerrar",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
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