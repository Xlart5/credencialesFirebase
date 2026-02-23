import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/models/employee_model.dart';
import '../widgets/computo_datasource.dart';

class ComputoScreen extends StatefulWidget {
  const ComputoScreen({super.key});

  @override
  State<ComputoScreen> createState() => _ComputoScreenState();
}

class _ComputoScreenState extends State<ComputoScreen> {
  late ComputoDataSource _dataSource;
  bool _hasSelection = false;
  bool _showOnlyPending = false;

  @override
  void initState() {
    super.initState();

    

  
  }

  // Esta función es llamada por el DataSource cada vez que algo cambia (selección o acceso)
  void _updateState() {
    setState(() {
      _hasSelection = _dataSource.hasSelection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER Y TARJETAS KPI ---
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go("/"),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Control Central",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "PANEL DE CÓMPUTO",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Tarjetas Dashboard (Contadores)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    "TOTAL REGISTRADOS",
                    _dataSource.totalCount,
                    Icons.people_alt_outlined,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildKpiCard(
                    "CON ACCESO",
                    _dataSource.conAccesoCount,
                    Icons.check_circle_outline,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildKpiCard(
                    "PENDIENTES (SIN ACCESO)",
                    _dataSource.sinAccesoCount,
                    Icons.do_not_disturb_alt,
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- 2. TARJETA PRINCIPAL CON TABLA ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- CONTROLES DE LA TABLA (HEADER) ---
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.list_alt,
                              color: Colors.amber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Text(
                            "Gestión de Acceso",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),

                          // Filtro "Solo Sin Acceso"
                          FilterChip(
                            label: const Text("Ocultar habilitados"),
                            labelStyle: TextStyle(
                              color: _showOnlyPending
                                  ? Colors.red.shade700
                                  : Colors.grey.shade700,
                              fontWeight: _showOnlyPending
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            selected: _showOnlyPending,
                            showCheckmark: false,
                            avatar: Icon(
                              _showOnlyPending
                                  ? Icons.visibility_off
                                  : Icons.filter_list,
                              size: 16,
                              color: _showOnlyPending
                                  ? Colors.red.shade700
                                  : Colors.grey.shade600,
                            ),
                            backgroundColor: Colors.grey.shade100,
                            selectedColor: Colors.red.shade50,
                            side: BorderSide(
                              color: _showOnlyPending
                                  ? Colors.red.shade200
                                  : Colors.grey.shade300,
                            ),
                            onSelected: (bool value) {
                              setState(() {
                                _showOnlyPending = value;
                                _dataSource.setFilter(
                                  value,
                                ); // Filtramos en la base de datos
                              });
                            },
                          ),
                          const SizedBox(width: 15),

                          // Buscador
                          SizedBox(
                            width: 250,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Buscar por CI o Nombre",
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 15,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),

                          // Botón de Dar Acceso Masivo
                          ElevatedButton.icon(
                            onPressed: _hasSelection
                                ? () {
                                    _dataSource.darAccesoMasivo();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Accesos otorgados correctamente',
                                        ),
                                        backgroundColor: Colors.teal,
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text(
                              "Dar Acceso",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade200,
                              disabledForegroundColor: Colors.grey.shade400,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // --- TABLA ---
                    Expanded(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          cardColor: Colors.white,
                          colorScheme: Theme.of(
                            context,
                          ).colorScheme.copyWith(surface: Colors.white),
                          dividerColor: Colors.grey.shade200,
                          dataTableTheme: const DataTableThemeData(
                            headingTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            child: PaginatedDataTable(
                              source: _dataSource,
                              showCheckboxColumn: true,
                              columnSpacing: 60,
                              horizontalMargin: 30,
                              rowsPerPage: 5,
                              dataRowMaxHeight: 75,
                              dataRowMinHeight: 65,
                              columns: const [
                                DataColumn(label: Text("Empleado")),
                                DataColumn(label: Text("Cédula de identidad")),
                                DataColumn(label: Text("Unidad")),
                                DataColumn(label: Text("Celular")),
                                DataColumn(label: Text("Estado")),
                                DataColumn(label: Text("Acciones")),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DE APOYO: TARJETAS KPI ---
  Widget _buildKpiCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
