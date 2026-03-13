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
    if (fechaRaw == null ||
        fechaRaw.toString() == "null" ||
        fechaRaw.toString().isEmpty) {
      return "Sin fecha";
    }
    try {
      DateTime dt = DateTime.parse(fechaRaw.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return "Error fecha";
    }
  }

  // 🔥 Extracción del cargo usando el campo real del historial
  String _obtenerNombreCargo(dynamic h) {
    if (h['cargoProcesoNombre'] != null)
      return h['cargoProcesoNombre'].toString();
    if (h['cargoNombre'] != null) return h['cargoNombre'].toString();
    if (h['cargo'] != null) return h['cargo'].toString();
    return "CARGO NO REGISTRADO";
  }

  Future<void> _imprimirUnico(BuildContext context, dynamic h) async {
    await initializeDateFormatting('es', null);
    final formatPdf = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es');

    DateTime inicio = h['fechaInicio'] != null
        ? DateTime.parse(h['fechaInicio'])
        : DateTime.now();
    DateTime fin = h['fechaFin'] != null
        ? DateTime.parse(h['fechaFin'])
        : DateTime.now();

    final datos = CertificadoData(
      employee: employee.copyWith(cargo: _obtenerNombreCargo(h)),
      fechaInicio: formatPdf.format(inicio),
      fechaFin: formatPdf.format(fin),
    );

    final pdfBytes = await CertificatePdfService.generateCertificadosPdf([
      datos,
    ]);
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
                        "Historial de Contratos\n${employee.nombre}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
                child: FutureBuilder<List<dynamic>>(
                  future: provider.obtenerHistorialPersonal(employee.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError)
                      return Center(child: Text("Error: ${snapshot.error}"));
                    if (!snapshot.hasData || snapshot.data!.isEmpty)
                      return const Center(child: Text("No hay registros."));

                    final historiales = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: historiales.length,
                      itemBuilder: (ctx, i) {
                        final h = historiales[i];
                        bool esActivo = h['activo'] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: 2,
                          color: esActivo ? Colors.green.shade50 : Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(15),
                            leading: CircleAvatar(
                              backgroundColor: esActivo
                                  ? Colors.green
                                  : Colors.grey,
                              child: const Icon(
                                Icons.work,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              _obtenerNombreCargo(h).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Inicio: ${_formatFecha(h['fechaInicio'])}  •  Fin: ${_formatFecha(h['fechaFin'])}\nEstado: ${esActivo ? 'EN CURSO' : 'FINALIZADO'}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.print,
                                color: AppColors.primaryDark,
                              ),
                              onPressed: () => _imprimirUnico(context, h),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                    ),
                    onPressed: () => showNuevoContratoSheet(context, employee),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text(
                      "Asignar Nuevo Contrato",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
