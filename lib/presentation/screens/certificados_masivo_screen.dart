import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import '../../config/provider/employee_provider.dart';
import '../../config/models/employee_model.dart';
import '../../config/theme/app_colors.dart';
import '../../config/helpers/certificate_pdf_service.dart';
import '../widgets/historial_personal_sheet.dart';
import '../widgets/sidebar_filter.dart'; 

class CertificadosMasivoScreen extends StatefulWidget {
  const CertificadosMasivoScreen({super.key});

  @override
  State<CertificadosMasivoScreen> createState() =>
      _CertificadosMasivoScreenState();
}

class _CertificadosMasivoScreenState extends State<CertificadosMasivoScreen> {
  String _searchQuery = "";
  List<Employee> _empleadosHistoricos = [];
  bool _isLoading = true;
  
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _cargarHistoricosDesdeFirebase();
  }

  Future<void> _cargarHistoricosDesdeFirebase() async {
    final provider = context.read<EmployeeProvider>();
    provider.clearCertificadoSelection();

    final personasRaw = await provider.obtenerPersonasHistoricasFirebase();
    
    final prefs = await SharedPreferences.getInstance();
    String rol = prefs.getString('rol') ?? '';
    String miUnidad = prefs.getString('nombreUnidad') ?? '';

    if (mounted) {
      setState(() {
        List<Employee> todos = personasRaw.map((p) => Employee(
          id: p['idBackend'] ?? 0,
          nombre: p['nombreCompleto'] ?? 'Sin Nombre',
          apellidoPaterno: '',
          apellidoMaterno: '',
          carnetIdentidad: p['ci'] ?? '',
          correo: '',
          celular: '',
          accesoComputo: false,
          estadoActual: 'CONTRATO TERMINADO',
          cargo: p['ultimoCargo'] ?? 'Sin Cargo',
          unidad: p['ultimaUnidad'] ?? 'Sin Unidad',
          photoUrl: '', 
          qrUrl: '', 
          Circu: '', 
          ImageId: 0,
          tipo: 'HISTORICO',
          impreso: p['impreso'] ?? false, 
        )).toList();

        if (rol == 'CONSULTA' && miUnidad.isNotEmpty) {
          _empleadosHistoricos = todos.where((emp) {
            return emp.unidad.trim().toLowerCase() == miUnidad.trim().toLowerCase();
          }).toList();
        } else {
          _empleadosHistoricos = todos; 
        }

        provider.setEmpleadosHistoricosTemporales(_empleadosHistoricos);
        _isLoading = false;
      });
    }
  }

  Future<void> _imprimirMasivo(BuildContext context, EmployeeProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Generando Certificados desde Firebase..."),
          ],
        ),
      ),
    );

    List<CertificadoData> datosAImprimir = [];
    await initializeDateFormatting('es', null);
    final formatPdf = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es');

    final seleccionados = provider.selectedForCertificados.toList();

    for (var emp in seleccionados) {
      final contratos = await provider.obtenerContratosDePersonaFirebase(emp.id.toString());
      
      for (var contrato in contratos) {
        DateTime inicio = DateTime.parse(contrato['fechaInicio']);
        DateTime fin = DateTime.parse(contrato['fechaFin']);

        datosAImprimir.add(
          CertificadoData(
            employee: emp, 
            fechaInicio: formatPdf.format(inicio),
            fechaFin: formatPdf.format(fin),
            cargoNombre: contrato['cargo'] ?? emp.cargo,
            cargoDescripcion: contrato['cargoDescripcion'] ?? 'Servicio de Terceros',
            tipoContrato: contrato['tipoContrato'] ?? 'Administrativo I',
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context);

    if (datosAImprimir.isNotEmpty) {
      final pdfBytes = await CertificatePdfService.generateCertificadosPdf(datosAImprimir);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Lote_Certificados.pdf',
      );

      setState(() => _isLoading = true);
      final ids = seleccionados.map((e) => e.id).toList();
      await provider.actualizarEstadoImpresoFirebase(ids, true);
      await _cargarHistoricosDesdeFirebase();
      provider.clearCertificadoSelection();

    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se encontraron contratos para imprimir"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _marcarSeleccionadosComoImpresos(EmployeeProvider provider) async {
    setState(() => _isLoading = true);
    final ids = provider.selectedForCertificados.map((e) => e.id).toList();
    await provider.actualizarEstadoImpresoFirebase(ids, true);
    await _cargarHistoricosDesdeFirebase();
    provider.clearCertificadoSelection();
  }

  Future<void> _imprimirIndividual(BuildContext context, Employee emp, EmployeeProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Generando Certificado..."),
          ],
        ),
      ),
    );

    List<CertificadoData> datosAImprimir = [];
    await initializeDateFormatting('es', null);
    final formatPdf = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es');

    final contratos = await provider.obtenerContratosDePersonaFirebase(emp.id.toString());
    for (var contrato in contratos) {
      DateTime inicio = DateTime.parse(contrato['fechaInicio']);
      DateTime fin = DateTime.parse(contrato['fechaFin']);

      datosAImprimir.add(CertificadoData(
        employee: emp, 
        fechaInicio: formatPdf.format(inicio),
        fechaFin: formatPdf.format(fin),
        cargoNombre: contrato['cargo'] ?? emp.cargo,
        cargoDescripcion: contrato['cargoDescripcion'] ?? 'Servicio de Terceros',
        tipoContrato: contrato['tipoContrato'] ?? 'Administrativo I',
      ));
    }

    if (mounted) Navigator.pop(context);

    if (datosAImprimir.isNotEmpty) {
      final pdfBytes = await CertificatePdfService.generateCertificadosPdf(datosAImprimir);
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: 'Certificado_${emp.ci}.pdf');

      setState(() => _isLoading = true);
      await provider.actualizarEstadoImpresoFirebase([emp.id], true);
      await _cargarHistoricosDesdeFirebase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    final listaFiltrada = _empleadosHistoricos.where((emp) {
      bool matchesSearch = emp.ci.contains(_searchQuery) ||
          emp.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesUnidad = provider.selectedUnidadFilter == null || emp.unidad == provider.selectedUnidadFilter;
      bool matchesCargo = provider.selectedCargoFilter == null || emp.cargo == provider.selectedCargoFilter;
      bool matchesImpreso = provider.filtroImpreso == null || emp.impreso == provider.filtroImpreso;

      return matchesSearch && matchesUnidad && matchesCargo && matchesImpreso;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Impresión Masiva de Historiales", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _cargarHistoricosDesdeFirebase();
            },
          )
        ],
      ),
      floatingActionButton: provider.selectedForCertificados.isEmpty
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'btn_marcar',
                  backgroundColor: Colors.teal,
                  onPressed: () => _marcarSeleccionadosComoImpresos(provider),
                  label: const Text("Marcar Seleccionados como Impresos", style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.check, color: Colors.white),
                ),
                const SizedBox(width: 15),
                FloatingActionButton.extended(
                  heroTag: 'btn_imprimir',
                  backgroundColor: Colors.green,
                  onPressed: () => _imprimirMasivo(context, provider),
                  label: Text("Imprimir Seleccionados (${provider.selectedForCertificados.length})", style: const TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.print, color: Colors.white),
                ),
              ],
            ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SidebarFilter(hideEstados: true, showImpresoFilter: true), 

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Buscador de Certificados (Firebase)",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Buscar por CI o Nombre...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 20),
                  Expanded( // 🔥 Toma el espacio restante de la pantalla
                    child: SingleChildScrollView( // 🔥 ESTO SOLUCIONA EL OVERFLOW. Permite hacer scroll hacia abajo si la tabla es muy alta.
                      child: Theme(
                        data: Theme.of(context).copyWith(cardColor: Colors.white),
                        child: PaginatedDataTable(
                          header: const Text("Personal con historial archivado"),
                          columns: const [
                            DataColumn(label: Text("Cédula (CI)")),
                            DataColumn(label: Text("Nombre Completo")),
                            DataColumn(label: Text("Último Cargo")),
                            DataColumn(label: Text("Acciones")),
                          ],
                          source: CertificadosDataSource(listaFiltrada, context, _imprimirIndividual),
                          
                          rowsPerPage: _rowsPerPage,
                          availableRowsPerPage: const [10, 50, 100],
                          onRowsPerPageChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _rowsPerPage = value;
                              });
                            }
                          },
                          
                          showCheckboxColumn: true,
                        ),
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
}

class CertificadosDataSource extends DataTableSource {
  final List<Employee> employees;
  final BuildContext context;
  final Function(BuildContext, Employee, EmployeeProvider) onPrintIndividual;

  CertificadosDataSource(this.employees, this.context, this.onPrintIndividual);

  @override
  DataRow? getRow(int index) {
    if (index >= employees.length) return null;
    final emp = employees[index];
    final provider = context.read<EmployeeProvider>();

    return DataRow.byIndex(
      index: index,
      selected: provider.selectedForCertificados.contains(emp),
      onSelectChanged: (val) => provider.toggleCertificadoSelection(emp),
      color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        if (emp.impreso) return Colors.green.shade50; 
        return null;
      }),
      cells: [
        DataCell(Text(emp.ci, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(emp.nombreCompleto)),
        DataCell(Text(emp.cargo, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        DataCell(
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => showHistorialPersonalSheet(context, emp),
                child: const Text("Ver Historial", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.print, color: Colors.green),
                tooltip: "Imprimir Certificado",
                onPressed: () => onPrintIndividual(context, emp, provider),
              ),
            ],
          )
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => employees.length;
  @override
  int get selectedRowCount => 0;
}