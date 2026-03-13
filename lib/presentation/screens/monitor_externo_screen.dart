import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MonitorExternosScreen extends StatefulWidget {
  const MonitorExternosScreen({super.key});

  @override
  State<MonitorExternosScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorExternosScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  late DatabaseReference _dbRef;

  Map<String, dynamic> _persona = {};
  bool _esperando = true;
  int _ultimoTimestamp = 0;

  // 🔥 NUEVO: SISTEMA DE COLA (QUEUE)
  final List<Map<String, dynamic>> _colaDeEscaneos = [];
  bool _procesandoCola =
      false; // Nos avisa si la pantalla está ocupada mostrando a alguien

  @override
  void initState() {
    super.initState();

    _dbRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://credenciales-f2be2-default-rtdb.firebaseio.com',
    ).ref('ultimo escaneo');

    _configurarVoz();
    _escucharFirebase();
  }

  void _configurarVoz() async {
    await _flutterTts.setLanguage("es-ES");
    // Opcional: Esto hace que Flutter espere a que la voz termine de hablar
    await _flutterTts.awaitSpeakCompletion(true);
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

        // Evitamos procesar el mismo escaneo dos veces
        if (timestampLlegado == _ultimoTimestamp) return;
        _ultimoTimestamp = timestampLlegado;

        // 🔥 En lugar de mostrarlo directo, LO METEMOS A LA COLA
        _colaDeEscaneos.add(data);

        // Y le decimos al sistema que intente procesar la cola
        _procesarSiguienteEnCola();
      } catch (e) {
        print("🚨 ERROR: $e");
      }
    });
  }

  // 🔥 NUEVO: EL MOTOR QUE CONTROLA EL TIEMPO
  Future<void> _procesarSiguienteEnCola() async {
    // Si ya estamos mostrando a alguien, o no hay nadie en la cola, no hacemos nada
    if (_procesandoCola || _colaDeEscaneos.isEmpty) return;

    // Bloqueamos la pantalla para que nadie más interrumpa
    _procesandoCola = true;

    // Sacamos al PRIMERO que llegó a la fila
    final dataPersona = _colaDeEscaneos.removeAt(0);

    // 1. Mostramos su info en pantalla
    if (mounted) {
      setState(() {
        _persona = dataPersona;
        _esperando = false;
      });
    }

    // 2. Hacemos que hable la voz robótica
    await _hablar(dataPersona);

    // 3. TIEMPO DE LECTURA: Esperamos 4 segundos para que el guardia vea la pantalla
    await Future.delayed(const Duration(seconds: 4));

    // 4. Limpiamos la pantalla
    if (mounted) {
      setState(() => _esperando = true);
    }

    // Desbloqueamos el sistema
    _procesandoCola = false;

    // 5. ¡Llamamos recursivamente por si hay alguien más esperando en la cola!
    _procesarSiguienteEnCola();
  }

  Future<void> _hablar(Map<String, dynamic> data) async {
    final bool acceso = data['accesoComputo'] == true;
    final String nombre = data['nombre']?.toString() ?? '';
    final String apellido = data['apellidoPaterno']?.toString() ?? '';
    final String error = data['error']?.toString() ?? 'No registrado';

    final String tipoRegistro =
        data['tipoRegistro']?.toString().toLowerCase() ?? 'entrada';

    if (acceso) {
      if (tipoRegistro == 'salida') {
        await _flutterTts.speak(
          "Registro de salida exitoso. Hasta pronto, $nombre $apellido",
        );
      } else {
        await _flutterTts.speak(
          "Acceso permitido. Bienvenido, $nombre $apellido",
        );
      }
    } else {
      await _flutterTts.speak("Acceso denegado. $error");
    }
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Detenemos la voz si cierran la pantalla
    super.dispose();
  }

  // ==========================================================
  // LA INTERFAZ VISUAL SIGUE EXACTAMENTE IGUAL HACIA ABAJO
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    if (_esperando) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.amber, size: 100),
              const SizedBox(height: 20),
              const Text(
                "MONITOR DE ACCESO ACTIVO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Mostramos cuántos están en fila (Opcional, es un buen detalle visual)
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

    final IconData mainIcon = acceso
        ? (tipoRegistro == 'salida' ? Icons.exit_to_app : Icons.verified_user)
        : Icons.cancel;

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
            Icon(
              mainIcon,
              size: size.height * 0.15,
              color: const Color(0xFF1E293B),
            ),
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
    final String nombreCompleto = "$nombreStr $apellidoStr".trim();
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
