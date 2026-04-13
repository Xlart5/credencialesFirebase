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
  List<Employee> _empleadosHistoricos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistoricosDesdeFirebase();
  }

  // 🔥 DESCARGAMOS EL PERSONAL HISTÓRICO DE FIREBASE AL INICIAR
// 🔥 DESCARGAMOS EL PERSONAL HISTÓRICO DE FIREBASE AL INICIAR
  Future<void> _cargarHistoricosDesdeFirebase() async {
    final provider = context.read<EmployeeProvider>();
    provider.clearCertificadoSelection();

    final personasRaw = await provider.obtenerPersonasHistoricasFirebase();
    
    if (mounted) {
      setState(() {
        // Mapeamos los datos de Firebase a nuestra clase Employee
        _empleadosHistoricos = personasRaw.map((p) => Employee(
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
          
          // 🔥 AQUÍ AGREGAMOS LOS CAMPOS REQUERIDOS FALTANTES CON VALORES POR DEFECTO
          photoUrl: '', // o 'imagen': '' dependiendo de cómo se llame exactamente en tu modelo
          qrUrl: '', // o 'qr': ''
         
          tipo: 'HISTORICO', Circu: '', ImageId: 0,
          // colorEstado: Colors.grey, <-- Descomenta esta línea si también te pide el color
        )).toList();
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

    for (var emp in provider.selectedForCertificados) {
      // 🔥 OBTENEMOS LOS CONTRATOS CERRADOS DE FIREBASE
      final contratos = await provider.obtenerContratosDePersonaFirebase(emp.id.toString());
      
      for (var contrato in contratos) {
        DateTime inicio = DateTime.parse(contrato['fechaInicio']);
        DateTime fin = DateTime.parse(contrato['fechaFin']);

        datosAImprimir.add(
          CertificadoData(
            employee: emp.copyWith(cargo: contrato['cargo']),
            fechaInicio: formatPdf.format(inicio),
            fechaFin: formatPdf.format(fin),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    final listaFiltrada = _empleadosHistoricos.where((emp) {
      return emp.ci.contains(_searchQuery) ||
          emp.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase());
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
          : FloatingActionButton.extended(
              backgroundColor: Colors.green,
              onPressed: () => _imprimirMasivo(context, provider),
              label: Text("Imprimir Seleccionados (${provider.selectedForCertificados.length})"),
              icon: const Icon(Icons.print),
            ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
        padding: const EdgeInsets.all(20.0),
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
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 20),
            Expanded(
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
        DataCell(Text(emp.ci, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(emp.nombreCompleto)),
        DataCell(Text(emp.cargo, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        DataCell(
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => showHistorialPersonalSheet(context, emp),
            child: const Text("Ver Historial", style: TextStyle(color: Colors.white)),
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