import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import '../../config/models/employee_model.dart';

// 🔥 EL MODELO INDEPENDIENTE
class CertificadoData {
  final Employee employee; 
  final String fechaInicio;
  final String fechaFin;
  final String cargoNombre;
  final String cargoDescripcion;
  final String tipoContrato;

  CertificadoData({
    required this.employee,
    required this.fechaInicio,
    required this.fechaFin,
    required this.cargoNombre,
    required this.cargoDescripcion,
    required this.tipoContrato, 
  });
}

class CertificatePdfService {
  static const String _logoPath = 'assets/images/logo_ted.png'; 

  static Future<Uint8List> generateCertificadosPdf(List<CertificadoData> dataList) async {
    final doc = pw.Document();
    final logoImage = pw.MemoryImage((await rootBundle.load(_logoPath)).buffer.asUint8List());

    await initializeDateFormatting('es', null);
    final DateFormat formatter = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es');
    String fechaActualStr = formatter.format(DateTime.now());

    for (var data in dataList) {
      final emp = data.employee;

      final String funcionesCompuestas = 
          '${data.cargoDescripcion} - ${data.cargoNombre}';

      doc.addPage(
        pw.Page(
          // 🔥 1. CAMBIADO A FORMATO A4
          pageFormat: PdfPageFormat.a4,
          // 🔥 2. AJUSTE DE MÁRGENES: Reducimos el inferior a 30 para que baje más el pie
          margin: const pw.EdgeInsets.only(left: 80, right: 80, top: 10, bottom: 30),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ==========================================
                // HEADER CON LOGO
                // ==========================================
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 90, height: 90, child: pw.Image(logoImage)),
                        pw.Text('Tribunal Electoral Departamental', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text('COCHABAMBA', style: const pw.TextStyle(fontSize: 10)),
                        
                      ],
                    ),
                    
                  ],
                ),
                pw.SizedBox(height: 15),

                // ==========================================
                // PÁRRAFO "EL SUSCRITO..."
                // ==========================================
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: PdfPageFormat.a4.width * 0.45,
                    child: pw.Text(
                      'EL SUSCRITO RESPONSABLE DE POA Y RECURSOS HUMANOS DEL O.E.P. - TRIBUNAL ELECTORAL DPTAL. DE COCHABAMBA, A PETICIÓN ESCRITA DE LA PARTE INTERESADA.',
                      textAlign: pw.TextAlign.justify,
                      style: pw.TextStyle(fontSize: 14, height: 1.8, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // ==========================================
                // TÍTULO
                // ==========================================
                pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 10),child: pw.Text('CERTIFICA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20))),
                pw.SizedBox(height: 15),

                // ==========================================
                // PÁRRAFO PRINCIPAL
                // ==========================================
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.RichText(
                    textAlign: pw.TextAlign.justify,
                    text: pw.TextSpan(
                      style: const pw.TextStyle(fontSize: 12, lineSpacing: 5), 
                      children: [
                        const pw.TextSpan(text: 'Que, el(la) Sr.(a) '),
                        pw.TextSpan(
                          text: emp.nombreCompleto.toUpperCase(), 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
                        ),
                        const pw.TextSpan(text: ' con Cedula de Identidad. No. '),
                        pw.TextSpan(
                          text: emp.carnetIdentidad , 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
                        ),
                        
                        const pw.TextSpan(text: ' desempeñó las funciones como '),
                        
                        pw.TextSpan(
                          text: funcionesCompuestas.toUpperCase(), 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
                        ),
                        
                        const pw.TextSpan(
                          text: ', durante el Proceso de Elecciones de autoridades politicas departamentales, regionales y municipales (Elecciones Subnacionales 2026), comprendido entre el '
                        ),
                        pw.TextSpan(
                          text: data.fechaInicio, 
                          
                        ),
                        const pw.TextSpan(text: ' al '),
                        pw.TextSpan(
                          text: data.fechaFin, 
                          
                        ),
                        const pw.TextSpan(
                          text: ', cargo en el cual ha demostrado compromiso y responsabilidad en las labores encomendadas, así como seriedad y puntualidad.'
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 🔥 3. ESPACIO REDUCIDO (Antes 60, ahora 30 para que suba el párrafo final)
                pw.SizedBox(height: 30),

                // ==========================================
                // FRAS DE CIERRE Y FECHA
                // ==========================================
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: PdfPageFormat.a4.width * 0.7,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Es cuanto certifico en honor a la verdad y para fines consiguientes del interesado.', 
                           
                          style: const pw.TextStyle(fontSize: 12, height: 2.0)
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text('Cochabamba, $fechaActualStr', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                
                // El Spacer se encarga de empujar el footer hacia abajo (hacia el margen bottom de 30 que pusimos)
                pw.Spacer(),
                
                // ==========================================
                // PIE DE PÁGINA (DIRECCIÓN)
                // ==========================================
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('C.C. Arch.\nDCF', style: const pw.TextStyle(fontSize: 8, height: 1.3)),
                    pw.SizedBox(height: 10),
                    pw.Container(width: double.infinity, height: 1, color: PdfColors.grey300),
                    pw.SizedBox(height: 5),
                    pw.Center(
                      child: pw.Text(
                        'Cala Cala, avenida Simón López Nº O-325. Teléfonos: 4430551 - 4430552. Fax: 4430341\nSitio Web: cochabamba.oep.org.bo',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }
    return doc.save();
  }
}