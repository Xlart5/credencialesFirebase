import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // 🔥 OBLIGATORIO PARA EL COMPUTE
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';

class PdfGeneratorService {
  static const double cardWidth = 270.0;
  static const double cardHeight = 171.0;

  // ==========================================
  // 1. EL JEFE (Se ejecuta en la pantalla principal)
  // ==========================================
  static Future<Uint8List> generateCredentialsPdf(List<Employee> employees) async {
    // Leemos los archivos de la carpeta assets aquí, porque el "sótano" (Isolate)
    // no tiene acceso a las carpetas del sistema.
    final frontData = await rootBundle.load('assets/images/card_template_front.png');
    final backData = await rootBundle.load('assets/images/ATRAS_EVENTUAL_2025.png');
    final tedData = await rootBundle.load('assets/images/logo_ted.png');
    final elecData = await rootBundle.load('assets/images/logo_elecciones.png');

    // Metemos los bytes puros y los empleados en un Map (Una caja)
    final Map<String, dynamic> dataAEnviar = {
      'employees': employees,
      'frontBytes': frontData.buffer.asUint8List(),
      'backBytes': backData.buffer.asUint8List(),
      'tedBytes': tedData.buffer.asUint8List(),
      'elecBytes': elecData.buffer.asUint8List(),
    };

    // Mandamos todo al procesador secundario con compute
    return await compute(_generarPdfEnSotano, dataAEnviar);
  }

  // ==========================================
  // 2. EL SÓTANO (Trabaja en segundo plano sin congelar)
  // ==========================================
  static Future<Uint8List> _generarPdfEnSotano(Map<String, dynamic> data) async {
    // 1. Desempacamos la caja
    final employees = data['employees'] as List<Employee>;
    
    // 2. Reconstruimos las imágenes en la memoria del sótano
    final templateFront = pw.MemoryImage(data['frontBytes']);
    final templateBack = pw.MemoryImage(data['backBytes']);
    final logoTed = pw.MemoryImage(data['tedBytes']);
    final logoElecciones = pw.MemoryImage(data['elecBytes']);

    final pdf = pw.Document();
    final pageFormat = PdfPageFormat.a4;
    const int itemsPerPage = 10;

    for (var i = 0; i < employees.length; i += itemsPerPage) {
      final chunk = employees.sublist(
        i,
        (i + itemsPerPage) < employees.length ? i + itemsPerPage : employees.length,
      );

      // --- 🚀 MEGA OPTIMIZACIÓN DE DESCARGAS ---
      // Disparamos QRs y Fotos al mismo tiempo
      final qrsFuture = Future.wait(chunk.map((emp) async {
        if (emp.qrUrl.isEmpty) return logoTed;
        try {
          final res = await http.get(Uri.parse(emp.qrUrl));
          if (res.statusCode == 200) return pw.MemoryImage(res.bodyBytes);
        } catch (_) {}
        return logoTed;
      }));

      final photosFuture = Future.wait(chunk.map((emp) async {
        if (emp.photoUrl.isEmpty) return logoTed;
        try {
          final res = await http.get(Uri.parse(emp.photoUrl));
          if (res.statusCode == 200) return pw.MemoryImage(res.bodyBytes);
        } catch (_) {}
        return logoTed;
      }));

      // Esperamos a que ambas listas terminen simultáneamente
      final results = await Future.wait([qrsFuture, photosFuture]);
      final List<pw.ImageProvider> qrs = results[0];
      final List<pw.ImageProvider> photos = results[1];

      // --- PÁGINA 1: FRENTE ---
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: cardWidth / cardHeight,
              crossAxisSpacing: 10,
              mainAxisSpacing: 5,
              children: List.generate(itemsPerPage, (index) {
                if (index < chunk.length) {
                  return _buildFrontCard(
                    chunk[index], photos[index], templateFront,
                    logoTed, logoElecciones, qrs[index] // Pásale tu lógica de QR
                  );
                } else {
                  return pw.SizedBox(width: cardWidth, height: cardHeight);
                }
              }),
            );
          },
        ),
      );

      // --- PÁGINA 2: ATRÁS (Espejo) ---
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          build: (pw.Context context) {
            final List<int?> mirrorIndexes = List.filled(itemsPerPage, null);
            for (int j = 0; j < chunk.length; j++) {
              final int row = j ~/ 2;
              final int col = j % 2;
              final int mirrorCol = (col == 0) ? 1 : 0;
              final int newIndex = (row * 2) + mirrorCol;
              if (newIndex < itemsPerPage) mirrorIndexes[newIndex] = j;
            }

            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: cardWidth / cardHeight,
              crossAxisSpacing: 10,
              mainAxisSpacing: 5,
              children: List.generate(itemsPerPage, (index) {
                if (mirrorIndexes[index] != null) {
                  return _buildBackCard(templateBack);
                } else {
                  return pw.SizedBox(width: cardWidth, height: cardHeight);
                }
              }),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // 👇 MANTÉN TUS DISEÑOS EXACTAMENTE IGUAL AQUÍ 👇
  // static pw.Widget _buildFrontCard(...) { ... }
  // static pw.Widget _buildBackCard(...) { ... }


  static Future<pw.MemoryImage> _loadAsset(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      return pw.MemoryImage(
        Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
      );
    }
  }

  // --- DISEÑO FRONTAL ---
  static pw.Widget _buildFrontCard(
    Employee emp,
    pw.ImageProvider photo,
    pw.ImageProvider bg,
    pw.ImageProvider logoTed,
    pw.ImageProvider logoElec,
    pw.ImageProvider qrs,
  ) {
    // 👇 LA MAGIA CONDICIONAL EMPIEZA AQUÍ 👇
    final String cargoMinusculas = emp.cargo.toString().toLowerCase();
    final bool esNotario = cargoMinusculas.contains('notari');
    // 👆 LA MAGIA CONDICIONAL TERMINA AQUÍ 👆

    return pw.Container(
      width: cardWidth,
      height: cardHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        color: PdfColors.white,
      ),
      child: pw.Stack(
        children: [
          // 1. Fondo
          pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.fill)),

          // 2. Header

          // 3. QR o CIRCUNSCRIPCIÓN (Reemplazado con la condición)
          pw.Positioned(
            top: 30,
            left: 30,
            child: esNotario
                // SI ES NOTARIO: Mostramos la cajita de Circunscripción
                ? pw.Container(
                    width: 70,
                    height: 70,

                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.SizedBox(height: 5),
                        pw.Text(
                          // Aquí llamamos a tu variable de circunscripción
                          emp.Circu.toString(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 30,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                // SI NO ES NOTARIO: Mostramos el QR normal
                : pw.Container(
                    width: 70,
                    height: 70,
                    color: PdfColors.white,
                    child: pw.Image(qrs, fit: pw.BoxFit.cover),
                  ),
          ),

          // 4. Logo TED
          pw.Positioned(
            top: 110,
            left: 78,
            child: pw.Container(
              width: 20,
              height: 20,
              child: pw.Image(logoTed),
            ),
          ),

          // 5. FOTO
          pw.Positioned(
            top: 35,
            right: 40,
            child: pw.Container(
              width: 60,
              height: 70,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColors.white, width: 1.5),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 5,
                verticalRadius: 5,
                child: pw.Image(photo, fit: pw.BoxFit.cover),
              ),
            ),
          ),

          // 6. DATOS
          pw.Positioned(
            bottom: 30,
            right: 15,
            child: pw.Container(
              width: 110,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "Ci: ${emp.ci}",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 5,
                    ),
                  ),
                  pw.SizedBox(height: 0.5),
                  pw.Text(
                    emp.nombreCompleto,
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 5,
                    ),
                  ),
                  pw.SizedBox(height: 0.5),
                  pw.Text(
                    emp.cargo.toString(),
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                    style: pw.TextStyle(fontSize: 4.5),
                  ),
                ],
              ),
            ),
          ),

          // 7. Logo Elecciones
          pw.Positioned(
            bottom: 28,
            left: 10,
            child: pw.Container(width: 45, child: pw.Image(logoElec)),
          ),

          // 8. Barra Negra
          pw.Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: pw.Container(
              height: 20,
              color: PdfColor.fromInt(0xFF222222),
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    "Personal Eventual",
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Elecciones Subnacionales 2026",
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 5.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DISEÑO TRASERO ---
  static pw.Widget _buildBackCard(pw.ImageProvider bg) {
    return pw.Container(
      width: cardWidth,
      height: cardHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Image(bg, fit: pw.BoxFit.fill),
    );
  }
}
