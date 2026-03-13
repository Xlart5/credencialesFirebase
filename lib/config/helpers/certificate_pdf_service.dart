import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/employee_model.dart';

// 🔥 CLASE CLAVE: Encapsula al empleado junto con las fechas de su contrato
class CertificadoData {
  final Employee employee;
  final String fechaInicio;
  final String fechaFin;

  CertificadoData({
    required this.employee,
    required this.fechaInicio,
    required this.fechaFin,
  });
}

class CertificatePdfService {
  // 🔥 RECIBE LA LISTA DE DATOS ENCAPSULADOS
  static Future<Uint8List> generateCertificadosPdf(
    List<CertificadoData> listaDatos,
  ) async {
    final pdf = pw.Document();
    await initializeDateFormatting('es', null);

    final tedLogoUrl = 'https://i.imgur.com/s9ukc28.png';
    final tedLogoResponse = await http.get(Uri.parse(tedLogoUrl));
    final tedLogoImage = pw.MemoryImage(tedLogoResponse.bodyBytes);

    for (var data in listaDatos) {
      final emp = data.employee;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(50),
          build: (pw.Context context) {
            final fechaHoy = DateFormat(
              'dd \'de\' MMMM \'de\' yyyy',
              'es',
            ).format(DateTime.now());

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Center(child: pw.Image(tedLogoImage, width: 150)),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Tribunal Electoral Departamental\nCOCHABAMBA",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  "EL SUSCRITO RESPONSABLE DE POA Y RECURSOS HUMANOS DEL O.E.P. - TRIBUNAL ELECTORAL DPTAL DE COCHABAMBA, A PETICIÓN ESCRITA DE LA PERSONA INTERESADA.",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    lineSpacing: 4,
                  ),
                ),
                pw.SizedBox(height: 50),
                pw.Container(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    "CERTIFICA:",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.RichText(
                  textAlign: pw.TextAlign.justify,
                  text: pw.TextSpan(
                    style: const pw.TextStyle(
                      fontSize: 15,
                      color: PdfColors.black,
                      lineSpacing: 10,
                    ),
                    children: [
                      const pw.TextSpan(text: "Que, el(la) Sr.(a) "),
                      pw.TextSpan(
                        text: emp.nombreCompleto.toUpperCase(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      const pw.TextSpan(text: " con CI. No. "),
                      pw.TextSpan(
                        text: emp.ci,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      const pw.TextSpan(
                        text: ", desempeñó las funciones como ",
                      ),
                      pw.TextSpan(
                        text: emp.cargo.toUpperCase(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      const pw.TextSpan(
                        text:
                            ", en el Tribunal Electoral Departamental de Cochabamba, durante el proceso electoral ELECCIONES DE AUTORIDADES POLÍTICAS DEPARTAMENTALES, REGIONALES Y MUNICIPALES (ELECCIONES SUBNACIONALES 2026), del ",
                      ),

                      // 🔥 AQUÍ SE IMPRIMEN LAS FECHAS DEL OBJETO
                      pw.TextSpan(
                        text: data.fechaInicio,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      const pw.TextSpan(text: " al "),
                      pw.TextSpan(
                        text: data.fechaFin,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),

                      const pw.TextSpan(
                        text:
                            ", demostrando durante su permanencia responsabilidad, honestidad y dedicación en las labores que le fueron encomendadas.",
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 50),
                pw.Text(
                  "Es cuanto se certifica en honor a la verdad y para fines consiguientes de la persona interesada.",
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 80),
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "Cochabamba, el $fechaHoy.",
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    return pdf.save();
  }
}
