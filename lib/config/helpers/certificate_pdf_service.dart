import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
// Asegúrate de que esta ruta a tu modelo Employee es correcta
import '../models/employee_model.dart';

class CertificatePdfService {
  // ==========================================
  // 🔥 FUNCIÓN: GENERAR CERTIFICADOS
  // ==========================================
  static Future<Uint8List> generateCertificadosPdf(
    List<Employee> empleados,
  ) async {
    final pdf = pw.Document();

    // Inicializamos el idioma español para las fechas
    await initializeDateFormatting('es', null);

    // 🔥 PRE-CARGAR LOGO DE TED DESDE URL
    final tedLogoUrl = 'https://i.imgur.com/s9ukc28.png';
    final tedLogoResponse = await http.get(Uri.parse(tedLogoUrl));
    final tedLogoImage = pw.MemoryImage(tedLogoResponse.bodyBytes);

    for (var emp in empleados) {
      pdf.addPage(
        pw.Page(
          // 📄 Formato Vertical (Letter o A4) para el nuevo diseño
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(50),
          build: (pw.Context context) {
            // 📅 Fecha de emisión del certificado (HOY)
            final fechaHoy = DateFormat(
              'dd \'de\' MMMM \'de\' yyyy',
              'es',
            ).format(DateTime.now());

            // Variables de contrato (puedes reemplazarlas por emp.fechaInicio si lo agregas a tu BD)
            final String fechaInicioContrato = "01 de enero de 2026";
            final String fechaFinContrato = "28 de febrero de 2026";

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // --- 1. LOGO DE TED EN PARTE SUPERIOR ---
                pw.Center(child: pw.Image(tedLogoImage, width: 150)),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Tribunal Electoral Departamental\nCOCHABAMBA",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),

                pw.SizedBox(height: 40),

                // --- 2. PREÁMBULO DEL RESPONSABLE (all caps y bold) ---
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

                // --- 3. LA PALABRA "CERTIFICA:" (bold y left-aligned) ---
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

                // --- 4. CUERPO DEL TEXTO (El párrafo oficial justificado) ---
                pw.RichText(
                  textAlign: pw
                      .TextAlign
                      .justify, // Texto alineado a ambos lados (oficial)
                  text: pw.TextSpan(
                    style: const pw.TextStyle(
                      fontSize: 15,
                      color: PdfColors.black,
                      lineSpacing:
                          10, // Interlineado amplio para lectura oficial
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
                            ", en el Tribunal Electoral Departamental de Cochabamba, durante el proceso electoral “ELECCIONES DE AUTORIDADES POLÍTICAS DEPARTAMENTALES, REGIONALES Y MUNICIPALES (ELECCIONES SUBNACIONALES 2026)”, del ",
                      ),
                      pw.TextSpan(
                        text: fechaInicioContrato,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      const pw.TextSpan(text: " al "),
                      pw.TextSpan(
                        text: fechaFinContrato,
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

                // --- 5. CONCLUSIÓN ---
                pw.Text(
                  "Es cuanto se certifica en honor a la verdad y para fines consiguientes de la persona interesada.",
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 14),
                ),

                pw.SizedBox(height: 80),

                // --- 6. FECHA DE EMISIÓN ---
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
