import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/provider/employee_provider.dart';
import '../widgets/computo_datasource.dart';
import '../widgets/computo_sidebar.dart';

class ComputoScreen extends StatefulWidget {
  const ComputoScreen({super.key});

  @override
  State<ComputoScreen> createState() => _ComputoScreenState();
}

class _ComputoScreenState extends State<ComputoScreen> {
  late ComputoDataSource _dataSource;
  bool _hasSelection = false;
  bool _showOnlyPending = false;

  late Set<String> _unidadesDisponibles;
  late Map<String, int> _conteoUnidades;

  @override
  void initState() {
    super.initState();
    _unidadesDisponibles = {};
    _conteoUnidades = {};
    _dataSource = ComputoDataSource(context, [], _updateState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
    });
  }

  void _updateState() {
    setState(() {
      _hasSelection = _dataSource.hasSelection;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    // 🔥 FILTRO MAESTRO CORREGIDO:
    // Ahora acepta "PERSONAL ACTIVO" o cualquier variación que contenga "ACTIV"
    final activeEmployees = provider.allEmployees.where((emp) {
      final estado = emp.estadoActual.trim().toUpperCase();
      return estado == "PERSONAL ACTIVO" ||
          estado == "PERSONA ACTIVA" ||
          estado.contains("ACTIV");
    }).toList();

    _unidadesDisponibles.clear();
    _conteoUnidades.clear();
    for (var emp in activeEmployees) {
      if (emp.unidad.isNotEmpty) {
        _unidadesDisponibles.add(emp.unidad);
        _conteoUnidades[emp.unidad] = (_conteoUnidades[emp.unidad] ?? 0) + 1;
      }
    }

    _dataSource.updateData(activeEmployees);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
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

            // TARJETAS KPI
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    "ACTIVOS REGISTRADOS",
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
                    "SIN ACCESO",
                    _dataSource.sinAccesoCount,
                    Icons.do_not_disturb_alt,
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SIDEBAR
                  ComputoSidebar(
                    dataSource: _dataSource,
                    unidades: _unidadesDisponibles,
                    conteoUnidades: _conteoUnidades,
                  ),

                  // TABLA
                  Expanded(
                    child: Container(
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

                                const SizedBox(width: 15),

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
                                      _dataSource.setPendingFilter(value);
                                    });
                                  },
                                ),
                                const SizedBox(width: 15),

                                Expanded(
                                  child: TextField(
                                    onChanged: (text) => setState(
                                      () => _dataSource.setSearchQuery(text),
                                    ),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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

                                ElevatedButton.icon(
                                  onPressed: _hasSelection
                                      ? () async {
                                          // 🔥 Agregamos async
                                          // Mostramos un mensajito de "Cargando"
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Guardando accesos...',
                                              ),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );

                                          // Llamamos a la API a través del DataSource
                                          final success = await _dataSource
                                              .darAccesoMasivo();

                                          if (success && context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Accesos otorgados correctamente',
                                                ),
                                                backgroundColor: Colors.teal,
                                              ),
                                            );
                                          } else if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Error al conectar con el servidor',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      : null,
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text(
                                    "Dar Acceso",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        Colors.grey.shade200,
                                    disabledForegroundColor:
                                        Colors.grey.shade400,
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

                          Expanded(
                            child: provider.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Theme(
                                    data: Theme.of(context).copyWith(
                                      cardColor: Colors.white,
                                      colorScheme: Theme.of(context).colorScheme
                                          .copyWith(surface: Colors.white),
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
                                            DataColumn(
                                              label: Text(
                                                "Cédula de identidad",
                                              ),
                                            ),
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
          ],
        ),
      ),
    );
  }

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
