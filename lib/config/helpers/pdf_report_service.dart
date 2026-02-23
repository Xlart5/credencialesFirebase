import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfReportService {
  static Future<Uint8List> generateCircunscripcionReport(
    String circunscripcion, 
    List<dynamic> data,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // 1. TÍTULO Y TOTAL
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('REPORTE: CIRCUNSCRIPCIÓN $circunscripcion', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('TOTAL: ${data.length} PERSONAS', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ]
              )
            ),
            pw.SizedBox(height: 20),

            // 2. TABLA DINÁMICA
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              // Cabeceras basadas en tu Swagger
              headers: ['CI', 'Nombre Completo', 'Celular', 'Correo', 'Tipo'],
              data: data.map((persona) {
                return [
                  persona['carnetIdentidad']?.toString() ?? '',
                  persona['nombreCompleto']?.toString() ?? '',
                  persona['celular']?.toString() ?? '',
                  persona['correo']?.toString() ?? '',
                  persona['tipo']?.toString() ?? '',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}