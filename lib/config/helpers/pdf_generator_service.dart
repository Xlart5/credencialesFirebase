import 'dart:typed_data';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/rendering.dart';
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
  static Future<Uint8List> generateCredentialsPdf(
    List<Employee> employees,
  ) async {
    final frontData = await rootBundle.load('assets/images/card_template_front.png');
    final backData = await rootBundle.load('assets/images/ATRAS_EVENTUAL_2025.png');
    final tedData = await rootBundle.load('assets/images/logo_ted.png');
    final elecData = await rootBundle.load('assets/images/logo_elecciones.png');

    final Map<String, dynamic> dataAEnviar = {
      'employees': employees,
      'frontBytes': frontData.buffer.asUint8List(),
      'backBytes': backData.buffer.asUint8List(),
      'tedBytes': tedData.buffer.asUint8List(),
      'elecBytes': elecData.buffer.asUint8List(),
    };

    return await compute(_generarPdfEnSotano, dataAEnviar);
  }

  // ==========================================
  // 2. EL SÓTANO (Trabaja en segundo plano sin congelar)
  // ==========================================
  static Future<Uint8List> _generarPdfEnSotano(
    Map<String, dynamic> data,
  ) async {
    final employees = data['employees'] as List<Employee>;

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
        (i + itemsPerPage) < employees.length
            ? i + itemsPerPage
            : employees.length,
      );

      final photosFuture = Future.wait(
        chunk.map((emp) async {
          if (emp.photoUrl.isEmpty) return logoTed;
          try {
            final res = await http.get(Uri.parse(emp.photoUrl));
            if (res.statusCode == 200) return pw.MemoryImage(res.bodyBytes);
          } catch (_) {}
          return logoTed;
        }),
      );

      final List<pw.ImageProvider> photos = await photosFuture;

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
                    chunk[index],
                    photos[index],
                    templateFront,
                    logoTed,
                    logoElecciones,
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

  // --- DISEÑO FRONTAL ---
  static pw.Widget _buildFrontCard(
    Employee emp,
    pw.ImageProvider photo,
    pw.ImageProvider bg,
    pw.ImageProvider logoTed,
    pw.ImageProvider logoElec,
  ) {
    final String cargoMinusculas = emp.cargo.toString().toLowerCase();

    // 🔥 VALIDACIONES
    final bool esCoordinadorNotario = cargoMinusculas.contains('coordinador') && cargoMinusculas.contains('notari');
    final bool esNotarioNormal = cargoMinusculas.contains('notari') && !esCoordinadorNotario;
    final bool esJuez = cargoMinusculas.contains('juez');
    
    // 🔥 NUEVA VALIDACIÓN PARA PLANTA
    final bool esPlanta = emp.tipo.toString().toUpperCase() == 'PLANTA';

    final String qrData = emp.qrUrl.isNotEmpty ? emp.qrUrl : "SIN_QR_ASIGNADO";

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

          // 2. LÓGICA DE LA ESQUINA
          pw.Positioned(
            top: esCoordinadorNotario ? 34 : 40, 
            left: 30,
            child: esNotarioNormal
                ? pw.Container(
                    width: 70,
                    height: 70,
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.SizedBox(height: 5),
                        pw.Text(
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
                : esCoordinadorNotario
                ? pw.Container(
                    width: 60,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          color: PdfColors.white,
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: qrData,
                            width: 52, 
                            height: 52,
                            color: PdfColors.black,
                            backgroundColor: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(
                              emp.Circu,
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : esJuez
                ? pw.Container(
                    width: 80, 
                    height: 60,
                    alignment: pw.Alignment.center,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          "JUEZ",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          "ELECTORAL",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                : pw.Container(
                    width: 60,
                    height: 60,
                    color: PdfColors.white,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrData,
                      width: 60,
                      height: 60,
                      color: PdfColors.black,
                      backgroundColor: PdfColors.white,
                    ),
                  ),
          ),

          // 3. Logo TED (Reacomodado dinámicamente)
          if (esPlanta)
            pw.Positioned(
              bottom: 25,
              left: 45, // 🔥 Centrado perfectamente debajo del QR
              child: pw.Container(
                width: 30, // Un poco más grande para que luzca bien solo
                height: 30,
                child: pw.Image(logoTed),
              ),
            )
          else
            pw.Positioned(
              top: 110,
              left: 78,
              child: pw.Container(
                width: 20,
                height: 20,
                child: pw.Image(logoTed),
              ),
            ),

          // 4. FOTO
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

          // 5. DATOS
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

          // 6. Logo Elecciones (Oculto si es Planta)
          if (!esPlanta)
            pw.Positioned(
              bottom: 28,
              left: 10,
              child: pw.Container(width: 45, child: pw.Image(logoElec)),
            ),

          // 7. Barra Negra (Texto dinámico)
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
                    // 🔥 Cambiamos el texto dinámicamente
                    esPlanta ? "SERVIDOR PÚBLICO" : "Personal Eventual",
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