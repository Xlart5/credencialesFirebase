import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MonitorScreen extends StatefulWidget {
  final String tipoPuerta; // 🔥 Recibe 'externos_entrada', 'externos_salida' o 'eventuales'

  const MonitorScreen({super.key, required this.tipoPuerta});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  late DatabaseReference _dbRef;

  Map<String, dynamic> _persona = {};
  bool _esperando = true;
  int _ultimoTimestamp = 0;

  final List<Map<String, dynamic>> _colaDeEscaneos = [];
  bool _procesandoCola = false;

  @override
  void initState() {
    super.initState();

    // 🔥 ESCUCHA AL CANAL ESPECÍFICO DE ESA PUERTA
    _dbRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://credenciales-f2be2-default-rtdb.firebaseio.com',
    ).ref('monitores/${widget.tipoPuerta}');

    _configurarVoz();
    _escucharFirebase();
  }

  void _configurarVoz() async {
    // Intentamos usar Español de México, si no, España
    try {
      await _flutterTts.setLanguage("es-MX");
    } catch (_) {
      await _flutterTts.setLanguage("es-ES"); 
    }
    
    // Velocidad ágil pero entendible
    await _flutterTts.setSpeechRate(0.8); 
    await _flutterTts.setPitch(1.0);      

    // No espera a terminar para liberar la pantalla
    await _flutterTts.awaitSpeakCompletion(false);
  }

  // 🔥 FUNCIÓN PARA LIMPIAR EL NOMBRE (Se queda porque te gustó)
  String _limpiarTexto(String textoRaw) {
    if (textoRaw.isEmpty) return '';
    
    String textoLimpio = textoRaw.toUpperCase();
    
    final palabrasAQuitar = [
      'EXTERNOS', 
      'EXTERNO', 
      'EVENTUALES', 
      'EVENTUAL', 
      'PLANTA',
      'PRENSA',
      'OBSERVADOR',
      'DELEGADO',
      'CANDIDATO'
    ];

    for (var palabra in palabrasAQuitar) {
      textoLimpio = textoLimpio.replaceAll(palabra, '').trim();
    }
    
    List<String> palabras = textoLimpio.split(' ');
    String resultado = '';
    for (var p in palabras) {
      if (p.isNotEmpty) {
        resultado += p[0].toUpperCase() + p.substring(1).toLowerCase() + ' ';
      }
    }
    return resultado.trim();
  }

  void _escucharFirebase() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value == null) return;

      try {
        final cleanJson = jsonEncode(event.snapshot.value);
        final Map<String, dynamic> data = jsonDecode(cleanJson);

        final int timestampLlegado = (data['timestamp'] is num)
            ? (data['timestamp'] as num).toInt()
            : 0;

        if (timestampLlegado == _ultimoTimestamp) return;
        _ultimoTimestamp = timestampLlegado;

        _colaDeEscaneos.add(data);
        _procesarSiguienteEnCola();
      } catch (e) {
        print("🚨 ERROR: $e");
      }
    });
  }

  Future<void> _procesarSiguienteEnCola() async {
    if (_procesandoCola || _colaDeEscaneos.isEmpty) return;
    _procesandoCola = true;

    final dataPersona = _colaDeEscaneos.removeAt(0);

    if (mounted) {
      setState(() {
        _persona = dataPersona;
        _esperando = false;
      });
    }

    _hablar(dataPersona);
    
    // Esperamos 2 segundos
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) setState(() => _esperando = true);
    _procesandoCola = false;
    _procesarSiguienteEnCola();
  }

  Future<void> _hablar(Map<String, dynamic> data) async {
    final bool acceso = data['accesoComputo'] == true;
    
    final String nombreRaw = data['nombre']?.toString() ?? '';
    final String apellidoRaw = data['apellidoPaterno']?.toString() ?? '';
    final String nombreLimpio = _limpiarTexto("$nombreRaw $apellidoRaw");
    
    final String error = data['error']?.toString() ?? 'No registrado';
    final String tipoRegistro = data['tipoRegistro']?.toString().toLowerCase() ?? 'entrada';

    if (acceso) {
      if (tipoRegistro == 'salida') {
        await _flutterTts.speak("Hasta pronto, $nombreLimpio");
      } else {
        await _flutterTts.speak("Bienvenido, $nombreLimpio");
      }
    } else {
      await _flutterTts.speak("Acceso denegado. $error");
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Widget _buildLogoTed(double size) {
    return Image.asset(
      'assets/images/logo_ted.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_esperando) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogoTed(200.0),
              const SizedBox(height: 30),
              Text(
                "MONITOR: PUERTA ${widget.tipoPuerta.toUpperCase()}", 
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _colaDeEscaneos.isNotEmpty
                    ? "Procesando... (${_colaDeEscaneos.length} en espera)"
                    : "Esperando escaneo en puerta...",
                style: TextStyle(
                  color: _colaDeEscaneos.isNotEmpty
                      ? Colors.amber
                      : Colors.white54,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                  SizedBox(width: 8),
                  Text(
                    "Conectado a Firebase RTDB",
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final bool acceso = _persona['accesoComputo'] == true;
    final String tipoRegistro =
        _persona['tipoRegistro']?.toString().toLowerCase() ?? 'entrada';
        
    final Color bgColor = acceso
        ? (tipoRegistro == 'salida'
              ? const Color(0xFF64B5F6)
              : const Color(0xFFFFD54F))
        : Colors.redAccent;
        
    final String title = acceso
        ? (tipoRegistro == 'salida'
              ? "REGISTRO DE\nSALIDA"
              : "ACCESO\nPERMITIDO")
        : "ACCESO\nDENEGADO";

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.05),
            _buildLogoTed(size.height * 0.18),
            SizedBox(height: size.height * 0.02),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                height: 1.1,
              ),
            ),
            SizedBox(height: size.height * 0.05),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  child: acceso
                      ? _buildPersonaInfo(_persona, size, tipoRegistro)
                      : _buildErrorMessage(
                          _persona['error']?.toString() ?? 'Sin acceso',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaInfo(
    Map<String, dynamic> persona,
    Size size,
    String tipoRegistro,
  ) {
    final String nombreStr = persona['nombre']?.toString() ?? '';
    final String apellidoStr = persona['apellidoPaterno']?.toString() ?? '';
    
    final String nombreCompleto = _limpiarTexto("$nombreStr $apellidoStr");
    
    final String imagenStr = persona['imagen']?.toString() ?? '';
    final String photoUrl = imagenStr.isNotEmpty
        ? imagenStr
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(nombreCompleto.isEmpty ? 'Externo' : nombreCompleto)}&background=random&color=fff';
    final String carnetStr =
        persona['carnetIdentidad']?.toString() ??
        persona['qr']?.toString() ??
        'S/N';
    final String hora =
        "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    final String textoHora = tipoRegistro == 'salida'
        ? "HORA DE SALIDA:"
        : "HORA DE INGRESO:";
    final Color colorHora = tipoRegistro == 'salida'
        ? Colors.blueAccent
        : Colors.green;

    return Column(
      children: [
        CircleAvatar(
          radius: size.height * 0.1,
          backgroundImage: NetworkImage(photoUrl),
        ),
        SizedBox(height: size.height * 0.03),
        const Text(
          "NOMBRE REGISTRADO",
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        Text(
          nombreCompleto.isEmpty ? "Personal Acreditado" : nombreCompleto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: size.height * 0.02),
        const Text(
          "IDENTIFICACIÓN",
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        Text(
          carnetStr,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(),
        ),
        Text(
          "$textoHora $hora",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorHora,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 100,
          ),
          const SizedBox(height: 20),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}