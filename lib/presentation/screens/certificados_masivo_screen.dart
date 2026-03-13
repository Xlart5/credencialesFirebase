import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../config/provider/employee_provider.dart';
import '../../config/models/employee_model.dart';
import '../../config/theme/app_colors.dart';
import '../../config/helpers/certificate_pdf_service.dart';
import '../widgets/historial_personal_sheet.dart';

class CertificadosMasivoScreen extends StatefulWidget {
  const CertificadosMasivoScreen({super.key});

  @override
  State<CertificadosMasivoScreen> createState() =>
      _CertificadosMasivoScreenState();
}

class _CertificadosMasivoScreenState extends State<CertificadosMasivoScreen> {
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🔥 AHORA LLAMA A LA FUNCIÓN AISLADA
      context.read<EmployeeProvider>().fetchPersonalParaMasivo();
    });
  }

  // 🔥 Función interna para extraer el cargo real del historial
  String _extraerCargoDelHistorial(dynamic h) {
    if (h['cargoProcesoNombre'] != null)
      return h['cargoProcesoNombre'].toString();
    if (h['cargoNombre'] != null) return h['cargoNombre'].toString();
    if (h['cargo'] != null) return h['cargo'].toString();
    return "CARGO HISTÓRICO";
  }

  Future<void> _imprimirMasivo(
    BuildContext context,
    EmployeeProvider provider,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<CertificadoData> datosAImprimir = [];
    await initializeDateFormatting('es', null);
    final formatPdf = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es');

    for (var emp in provider.selectedForCertificados) {
      final historial = await provider.obtenerHistorialPersonal(emp.id);
      // Filtramos contratos en false
      final contratosCerrados = historial
          .where((h) => h['activo'] == false)
          .toList();

      for (var contrato in contratosCerrados) {
        DateTime inicio = contrato['fechaInicio'] != null
            ? DateTime.parse(contrato['fechaInicio'])
            : DateTime.now();
        DateTime fin = contrato['fechaFin'] != null
            ? DateTime.parse(contrato['fechaFin'])
            : DateTime.now();

        // 🔥 Usamos el cargo real del historial para sobreescribir el null
        String cargoReal = _extraerCargoDelHistorial(contrato);

        datosAImprimir.add(
          CertificadoData(
            employee: emp.copyWith(cargo: cargoReal),
            fechaInicio: formatPdf.format(inicio),
            fechaFin: formatPdf.format(fin),
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context);

    if (datosAImprimir.isNotEmpty) {
      final pdfBytes = await CertificatePdfService.generateCertificadosPdf(
        datosAImprimir,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Lote_Certificados.pdf',
      );
      provider.clearCertificadoSelection();
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se encontraron contratos cerrados (false)"),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }

  // En tu método build:
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    // 🔥 AHORA FILTRA SOBRE LA LISTA DE MASIVO, NO LA PRINCIPAL
    final listaFiltrada = provider.empleadosMasivo.where((emp) {
      return emp.ci.contains(_searchQuery) ||
          emp.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Impresión Masiva de Historiales",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
      ),
      floatingActionButton: provider.selectedForCertificados.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.green,
              onPressed: () => _imprimirMasivo(context, provider),
              label: Text(
                "Imprimir Seleccionados (${provider.selectedForCertificados.length})",
              ),
              icon: const Icon(Icons.print),
            ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Buscador Global de Certificados",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar por CI o Nombre...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(cardColor: Colors.white),
                child: PaginatedDataTable(
                  header: const Text(
                    "Seleccione personal para imprimir contratos en 'false'",
                  ),
                  columns: const [
                    DataColumn(label: Text("Cédula (CI)")),
                    DataColumn(label: Text("Nombre Completo")),
                    DataColumn(label: Text("Acciones")),
                  ],
                  source: CertificadosDataSource(listaFiltrada, context),
                  rowsPerPage: 10,
                  showCheckboxColumn: true,
                ),
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
  CertificadosDataSource(this.employees, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= employees.length) return null;
    final emp = employees[index];
    final provider = context.read<EmployeeProvider>();

    return DataRow.byIndex(
      index: index,
      selected: provider.selectedForCertificados.contains(emp),
      onSelectChanged: (val) => provider.toggleCertificadoSelection(emp),
      cells: [
        DataCell(
          Text(emp.ci, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataCell(Text(emp.nombreCompleto)),
        DataCell(
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => showHistorialPersonalSheet(context, emp),
            child: const Text(
              "Ver Historial",
              style: TextStyle(color: Colors.white),
            ),
          ),
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
