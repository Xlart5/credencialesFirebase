import 'package:carnetizacion/config/provider/unidades_provider.dart';
import 'package:carnetizacion/presentation/widgets/unidad_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/models/unidad_model.dart';

class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({super.key});

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnidadesProvider>().fetchDatosUnidades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UnidadesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Gestión de Unidades/Secciones",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Administre las áreas y departamentos institucionales",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text(
                          "Registrar Nueva Sección",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          // TODO: Lógica para nueva sección
                        },
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),

                  // --- GRID DE UNIDADES ---
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      // Tarjeta para "Registrar Nueva"
                      _buildAddCard(),

                      // Tarjetas de Unidades de la BD
                      ...provider.unidades
                          .map(
                            (unidad) =>
                                _buildUnidadCard(context, unidad, provider),
                          )
                          .toList(),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // --- WIDGET: TARJETA DE AGREGAR ---
  Widget _buildAddCard() {
    return Container(
      width: 300,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Colors.blue, size: 30),
            SizedBox(height: 10),
            Text(
              "Registrar Nueva Sección",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: TARJETA DE UNIDAD ---
  Widget _buildUnidadCard(
    BuildContext context,
    UnidadModel unidad,
    UnidadesProvider provider,
  ) {
    return Container(
      width: 300,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Colors.amber, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: unidad.estado
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unidad.estado ? "ACTIVO" : "INACTIVO",
                  style: TextStyle(
                    color: unidad.estado ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            unidad.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2D3748),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.people, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                "${unidad.totalCargosProceso} Elementos asignados",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text(
                    "Editar",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => UnidadDetailsDialog(unidad: unidad),
                    );
                  },
                  child: const Text(
                    "Ver Detalles",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
