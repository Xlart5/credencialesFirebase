import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../config/models/employee_model.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/helpers/certificate_pdf_service.dart';
import 'nuevo_contrato_sheet.dart';

void showHistorialPersonalSheet(BuildContext context, Employee emp) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => HistorialPersonalSheet(employee: emp),
  );
}

class HistorialPersonalSheet extends StatelessWidget {
  final Employee employee;
  const HistorialPersonalSheet({super.key, required this.employee});

  String _formatFecha(dynamic fechaRaw) {
    if (fechaRaw == null || fechaRaw.toString().isEmpty) return "Sin fecha";
    try {
      DateTime dt = DateTime.parse(fechaRaw.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return "Error fecha";
    }
  }

  Future<void> _imprimirUnico(BuildContext context, Map<String, dynamic> contratoFirebase) async {
    await initializeDateFormatting('es', null);
    final formatPdf = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es');

    DateTime inicio = DateTime.parse(contratoFirebase['fechaInicio']);
    DateTime fin = DateTime.parse(contratoFirebase['fechaFin']);

    final datos = CertificadoData(
      employee: employee.copyWith(cargo: contratoFirebase['cargo'] ?? 'Sin Cargo'),
      fechaInicio: formatPdf.format(inicio),
      fechaFin: formatPdf.format(fin),
    );

    final pdfBytes = await CertificatePdfService.generateCertificadosPdf([datos]);
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Certificado_${employee.ci}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EmployeeProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Center(
        child: Container(
          width: 600,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Archivo Histórico Firebase\n${employee.nombreCompleto}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                // 🔥 LLAMAMOS A FIREBASE
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: provider.obtenerContratosDePersonaFirebase(employee.id.toString()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("Esta persona no tiene contratos archivados en Firebase.", style: TextStyle(color: Colors.grey)),
                      );
                    }

                    final historiales = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: historiales.length,
                      itemBuilder: (ctx, i) {
                        final h = historiales[i];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: 2,
                          color: Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(15),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.verified, color: Colors.white),
                            ),
                            title: Text(
                              (h['cargo'] ?? 'Sin Cargo').toString().toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Unidad: ${h['unidad'] ?? 'N/A'}\nInicio: ${_formatFecha(h['fechaInicio'])}  •  Fin: ${_formatFecha(h['fechaFin'])}\nEstado: ARCHIVADO",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.print, color: AppColors.primaryDark),
                              onPressed: () => _imprimirUnico(context, h),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}