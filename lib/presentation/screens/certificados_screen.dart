import 'package:carnetizacion/presentation/widgets/finalizar_contrato_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';
import '../widgets/side_menu.dart';

class CertificadosScreen extends StatefulWidget {
  const CertificadosScreen({super.key});

  @override
  State<CertificadosScreen> createState() => _CertificadosScreenState();
}

class _CertificadosScreenState extends State<CertificadosScreen> {
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usamos fetchPersonalActivo que llama a /api/personal/detalles
      context.read<EmployeeProvider>().fetchPersonalActivo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    final listaFiltrada = provider.allEmployees.where((emp) {
      final matchesEstado =
          emp.estadoActual.toUpperCase() == 'CREDENCIAL DEVUELTO';
      final matchesBusqueda =
          emp.ci.contains(_searchQuery) ||
          emp.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesEstado && matchesBusqueda;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Cierre de Contratos",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: () => context.push('/certificados-masivo'),
              icon: const Icon(Icons.collections_bookmark, color: Colors.white),
              label: const Text(
                "IMPRESIÓN MASIVA",
                style: TextStyle(color: Colors.white),
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

      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar por CI o Nombre...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : listaFiltrada.isEmpty
                  ? const Center(
                      child: Text("No hay personal pendiente de cierre."),
                    )
                  : ListView.builder(
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        final emp = listaFiltrada[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              emp.nombreCompleto,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // 🔥 ESTE ES EL CAMBIO: Ya no hay FutureBuilder.
                            // Leemos el cargo directamente de 'emp.cargo' porque el endpoint ya nos lo da.
                            // Esto arregla que tu red se sature de peticiones.
                            subtitle: Text(
                              "CI: ${emp.ci}\nCargo: ${emp.cargo}",
                            ),

                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  showFinalizarContratoSheet(context, emp),
                              child: const Text(
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
    );
  }
}
