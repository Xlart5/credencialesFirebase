import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../config/provider/externos_provider.dart';

class GenerarQrsScreen extends StatefulWidget {
  const GenerarQrsScreen({super.key});

  @override
  State<GenerarQrsScreen> createState() => _GenerarQrsScreenState();
}

class _GenerarQrsScreenState extends State<GenerarQrsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cantidadCtrl = TextEditingController();

  String _tipoSeleccionado = 'Prensa';
  bool _isGenerating = false;

  final List<String> _tiposExternos = [
    'Prensa',
    'Observador',
    'Delegado',
    'Candidato',
    'Publico General',
  ];

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  // =======================================================
  // MAGIA PDF: CREAR Y MOSTRAR EL DOCUMENTO
  // =======================================================
  // =======================================================
  // MAGIA PDF: CREAR Y MOSTRAR EL DOCUMENTO
  // =======================================================
  // =======================================================
  // MAGIA PDF: CREAR Y MOSTRAR EL DOCUMENTO
  // =======================================================
  Future<void> _generarEImprimir() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    final provider = context.read<ExternosProvider>();
    int cantidad = int.parse(_cantidadCtrl.text);

    List<String> lotesQr = provider.generarLoteQRs(_tipoSeleccionado, cantidad);

    // 🔥 NUEVO: Cargamos el logo de las elecciones desde los assets
    final ByteData logoData = await rootBundle.load(
      'assets/images/logo_elecciones.png',
    );
    final pw.MemoryImage logoElecciones = pw.MemoryImage(
      logoData.buffer.asUint8List(),
    );

    final pdf = pw.Document();

    const double cardWidth = 270.0;
    const double cardHeight = 171.0;
    const int itemsPerPage = 10;

    for (var i = 0; i < lotesQr.length; i += itemsPerPage) {
      final chunk = lotesQr.sublist(
        i,
        (i + itemsPerPage) < lotesQr.length ? i + itemsPerPage : lotesQr.length,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: cardWidth / cardHeight,
              crossAxisSpacing: 10,
              mainAxisSpacing: 5,
              children: List.generate(itemsPerPage, (index) {
                if (index < chunk.length) {
                  // Le pasamos el logo a la función que dibuja la tarjeta
                  return _buildPdfCard(
                    chunk[index],
                    _tipoSeleccionado,
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
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Lote_Credenciales_${_tipoSeleccionado}_$cantidad.pdf',
    );

    setState(() => _isGenerating = false);
    _cantidadCtrl.clear();
  }

  // =======================================================
  // DISEÑO DE LA CREDENCIAL EXTERNA (270x171 PURO)
  // =======================================================
  // =======================================================
  // DISEÑO DE LA CREDENCIAL EXTERNA (270x171 PURO) - REFACTORIZADO
  // =======================================================
  // =======================================================
  // DISEÑO DE LA CREDENCIAL EXTERNA (GRIS + MARCA DE AGUA)
  // =======================================================
  // =======================================================
  // DISEÑO DE LA CREDENCIAL EXTERNA (GRIS + INICIAL GIGANTE)
  // =======================================================
  pw.Widget _buildPdfCard(
    String qrTexto,
    String tipo,
    pw.MemoryImage logoElecciones,
  ) {
    const double cardWidth = 270.0;
    const double cardHeight = 171.0;

    // 1. COLORES NEUTROS
    final colorFondoClaro = PdfColor.fromHex('#F5F5F5');
    final colorFondoOscuro = PdfColor.fromHex('#BDBDBD');
    final colorPlomoOscuro = PdfColor.fromHex('#2A2A2A');
    String inicial = '';
    if (tipo.toUpperCase() == 'PUBLICO GENERAL') {
      inicial = 'G';
    } else if (tipo.isNotEmpty) {
      inicial = tipo[0].toUpperCase();
    }

    // Extraemos solo la primera letra de la palabra (Ej: "PRENSA" -> "P")

    return pw.Container(
      width: cardWidth,
      height: cardHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.ClipRect(
        child: pw.Stack(
          children: [
            // 1. FONDO DEGRADADO GRIS
            pw.Positioned.fill(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    begin: pw.Alignment.topCenter,
                    end: pw.Alignment.bottomCenter,
                    colors: [colorFondoClaro, colorFondoOscuro],
                  ),
                ),
              ),
            ),

            // 2. FORMAS PERSONALIZADAS (Onda y Franja Negra)
            pw.Positioned.fill(
              child: pw.CustomPaint(
                size: const PdfPoint(cardWidth, cardHeight),
                painter: (PdfGraphics canvas, PdfPoint size) {
                  final width = size.x;
                  final height = size.y;

                  // Onda blanca
                  canvas.setFillColor(PdfColors.white);
                  canvas.moveTo(0, height);
                  canvas.lineTo(width * 0.35, height);
                  canvas.curveTo(
                    width * 0.60,
                    height * 0.7,
                    width * 0.30,
                    height * 0.3,
                    width * 0.45,
                    0,
                  );
                  canvas.lineTo(0, 0);
                  canvas.fillPath();

                  // Franja inferior oscura
                  canvas.setFillColor(colorPlomoOscuro);
                  canvas.drawRect(0, 0, width, height * 0.15);
                  canvas.fillPath();
                },
              ),
            ),

            // 🔥 3. MARCA DE AGUA GIGANTE (SOLO LA INICIAL)
            pw.Positioned.fill(
              left: 30,
              child: pw.Center(
                child: pw.Opacity(
                  opacity: 0.2, // Transparencia muy sutil
                  child: pw.Text(
                    inicial, // Usamos la variable que creamos arriba
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 160, // ¡Letra colosal!
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
            ),

            // 4. TÍTULO TED CENTRADO Y NEGRO
            pw.Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: pw.Center(
                child: pw.Text(
                  'TRIBUNAL ELECTORAL DEPARTAMENTAL DE COCHABAMBA',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ),

            // 5. LOGO DE ELECCIONES (A la derecha)
            pw.Positioned(
              top: 55,
              right: 30,
              child: pw.Container(
                width: 95,
                child: pw.Image(logoElecciones, fit: pw.BoxFit.contain),
              ),
            ),

            // 6. CÓDIGO QR (Izquierda sobre zona blanca)
            pw.Positioned(
              top: 45,
              left: 20,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                  boxShadow: [
                    pw.BoxShadow(blurRadius: 2, color: PdfColors.grey300),
                  ],
                ),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrTexto,
                  width: 65,
                  height: 65,
                ),
              ),
            ),

            // 7. TIPO DE CREDENCIAL EN LA FRANJA INFERIOR NEGRA
            pw.Positioned(
              bottom: 0,
              left: 0,
              right: 0,

              child: pw.Center(
                child: pw.Text(
                  tipo.toUpperCase(), // EJ: "PRENSA"
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white, // Blanco sobre negro
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================
  // INTERFAZ GRÁFICA DE LA WEB (FLUTTER)
  // =======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Generación de Lotes Externos",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2B5E),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Cree códigos QR vacíos para imprimir credenciales de acceso rápido.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            Center(
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "CONFIGURACIÓN DEL LOTE",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Tipo de Acreditación",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _tipoSeleccionado,
                        decoration: _inputDecoration(Icons.badge),
                        items: _tiposExternos
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _tipoSeleccionado = val!),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "Cantidad a Generar",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cantidadCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          Icons.tag,
                        ).copyWith(hintText: "Ej. 10"),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Ingrese una cantidad';
                          if (int.parse(v) <= 0) return 'Mínimo 1';
                          if (int.parse(v) > 200) return 'Máximo 200 por lote';
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _generarEImprimir,
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.print),
                          label: Text(
                            _isGenerating
                                ? "Generando PDF..."
                                : "Generar e Imprimir",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2B5E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E2B5E), width: 2),
      ),
    );
  }
}
