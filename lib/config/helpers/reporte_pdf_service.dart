import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class ReportePdfService {
  static Future<void> generarReporteAccesos(List<Map<String, dynamic>> datosFiltrados, String tituloFiltro, String fechaFiltro) async {
    final pdf = pw.Document();

    pw.ImageProvider? logoTed;
    try {
      final logoData = await rootBundle.load('assets/images/logo_ted.png');
      logoTed = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, 
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("TRIBUNAL ELECTORAL DEPARTAMENTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.Text("Auditoría Detallada de Accesos", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      pw.SizedBox(height: 5),
                      pw.Text("Filtro aplicado: $tituloFiltro", style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.blueGrey)),
                    ],
                  ),
                  if (logoTed != null) pw.Container(width: 50, child: pw.Image(logoTed)),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          List<pw.Widget> content = [];

          if (datosFiltrados.isEmpty) {
            content.add(pw.Center(child: pw.Text("No hay datos para el filtro seleccionado.")));
            return content;
          }

          for (int i = 0; i < datosFiltrados.length; i++) {
            final p = datosFiltrados[i];
            final bool estaAdentro = p['estaAdentro'] == true;
            
            String rol = p['tipo'] ?? '';
            String detalleCargo = rol;
            if (rol == 'EVENTUAL') {
              detalleCargo += " - ${p['unidad']} (${p['cargo']})";
            } else if (rol == 'DELEGADO' || rol == 'CANDIDATO') {
              if ((p['partidoPolitico'] ?? '').isNotEmpty) {
                detalleCargo += " - Partido: ${p['partidoPolitico']}";
              }
            } else if (rol == 'OBSERVADOR') {
              if ((p['asociacion'] ?? '').isNotEmpty) {
                detalleCargo += " - Org: ${p['asociacion']}";
              }
            }

            List<dynamic> accesosRaw = p['historialAccesos'] ?? [];
            accesosRaw.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

            List<Map<String, dynamic>> pares = [];
            Map<String, dynamic>? entradaPendiente;

            for (var acc in accesosRaw) {
              if (acc['tipo'] == 'entrada') {
                entradaPendiente = acc;
              } else if (acc['tipo'] == 'salida' && entradaPendiente != null) {
                pares.add({'entrada': entradaPendiente, 'salida': acc});
                entradaPendiente = null;
              } else if (acc['tipo'] == 'salida' && entradaPendiente == null) {
                pares.add({'entrada': null, 'salida': acc});
              }
            }
            if (entradaPendiente != null) {
              pares.add({'entrada': entradaPendiente, 'salida': null});
            }

            pw.Widget historyWidget;
            if (pares.isEmpty) {
              historyWidget = pw.Text("Sin registros de acceso.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey));
            } else {
              final List<List<String>> tableData = [
                ['Nº', 'Fecha Ingreso', 'Hora Ingreso', 'Fecha Salida', 'Hora Salida']
              ];
              
              int cont = 1;
              for (var par in pares) {
                final ent = par['entrada'];
                final sal = par['salida'];

                // 🔥 FILTRAMOS POR FECHA LÓGICA (EL TURNO)
                if (fechaFiltro != 'TODAS') {
                  String logicaEnt = ent != null ? ent['fechaLogica'] : '---';
                  String logicaSal = sal != null ? sal['fechaLogica'] : '---';
                  // Si ni la entrada ni la salida pertenecen a esa jornada, ignoramos el registro
                  if (logicaEnt != fechaFiltro && logicaSal != fechaFiltro) continue;
                }

                tableData.add([
                  cont.toString(),
                  ent != null ? ent['fecha'] : '---', // Seguimos imprimiendo la fecha real
                  ent != null ? ent['hora'] : '---',
                  sal != null ? sal['fecha'] : '---',
                  sal != null ? sal['hora'] : (estaAdentro ? 'Sigue Adentro' : '---'),
                ]);
                cont++;
              }

              if (tableData.length == 1) {
                historyWidget = pw.Text("Sin accesos en esta jornada.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey));
              } else {
                historyWidget = pw.TableHelper.fromTextArray(
                  headers: tableData.first,
                  data: tableData.sublist(1),
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF37474F)), 
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellAlignment: pw.Alignment.center,
                  columnWidths: {
                    0: const pw.FixedColumnWidth(25),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                  },
                );
              }
            }

            content.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  color: PdfColors.grey50, 
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("${i + 1}. ${p['nombreCompleto']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColor.fromInt(0xFF1E2B5E))),
                              pw.SizedBox(height: 2),
                              pw.Text(detalleCargo, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800)),
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: estaAdentro ? PdfColors.green100 : PdfColors.red100,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            estaAdentro ? "ESTADO: ADENTRO" : "ESTADO: AFUERA", 
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, 
                              fontSize: 8, 
                              color: estaAdentro ? PdfColors.green800 : PdfColors.red800
                            )
                          ),
                        ),
                      ]
                    ),
                    pw.SizedBox(height: 10),
                    historyWidget,
                  ]
                )
              )
            );
          }

          return content;
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Auditoria_Accesos.pdf',
    );
  }
}