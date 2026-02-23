import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  // Como la web corre en la misma PC que el servidor Dart, usamos localhost
  final _canal = WebSocketChannel.connect(Uri.parse('ws://10.95.70.221:8080'));
  final FlutterTts _flutterTts = FlutterTts();

  Map<String, dynamic>? _persona;
  bool _esperando = true; // Pantalla de espera inicial

  @override
  void initState() {
    super.initState();
    _configurarVoz();
    _escucharTunel();
  }

  void _configurarVoz() async {
    await _flutterTts.setLanguage("es-ES");
  }

  // Cambiamos la variable del canal por la referencia a Firebase
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(
    'ultimo_escaneo',
  );
  int _ultimoTimestampProcesado =
      0; // Para no repetir el audio de escaneos viejos al recargar la página

  void _escucharTunel() {
    // Escuchamos CUALQUIER cambio en "ultimo_escaneo" en tiempo real
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        // Convertimos el dato que llegó a un Map
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        // Verificamos que sea un escaneo NUEVO usando el timestamp
        final int timestampNuevo = data['timestamp'] ?? 0;
        if (timestampNuevo > _ultimoTimestampProcesado) {
          _ultimoTimestampProcesado = timestampNuevo;

          setState(() {
            _persona = data;
            _esperando = false;
          });

          _hablar(data); // Hace sonar el nombre o el error

          // Volver a la pantalla de "Esperando..." después de 8 segundos
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted) setState(() => _esperando = true);
          });
        }
      }
    });
  }

  void _hablar(Map<String, dynamic> data) async {
    final bool acceso = data['accesoComputo'] == true;
    if (acceso) {
      await _flutterTts.speak(
        "Acceso permitido. Bienvenido, ${data['nombre']} ${data['apellidoPaterno']}",
      );
    } else {
      await _flutterTts.speak(
        "Acceso denegado. ${data['error'] ?? 'No registrado'}",
      );
    }
  }

  @override
  void dispose() {
    _canal.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_esperando) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.qr_code_scanner, color: Colors.amber, size: 100),
              SizedBox(height: 20),
              Text(
                "MONITOR DE ACCESO ACTIVO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Esperando que el guardia escanee un QR...",
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // --- EL DISEÑO HERMOSO ---
    final size = MediaQuery.of(context).size;
    final bool acceso = _persona!['accesoComputo'] == true;

    final Color bgColor = acceso ? const Color(0xFFFFD54F) : Colors.redAccent;
    final IconData mainIcon = acceso ? Icons.verified_user : Icons.cancel;
    final String title = acceso ? "ACCESO\nPERMITIDO" : "ACCESO\nDENEGADO";

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
                      ? _buildPersonaInfo(_persona!, size)
                      : _buildErrorMessage(_persona!['error'] ?? 'Sin acceso'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaInfo(Map<String, dynamic> persona, Size size) {
    final String photoUrl =
        (persona['imagen'] != null && persona['imagen'].toString().isNotEmpty)
        ? persona['imagen']
        : 'https://ui-avatars.com/api/?name=${persona['nombre']}+${persona['apellidoPaterno']}&background=random&color=fff';
    final hora =
        "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";

    return Column(
      children: [
        CircleAvatar(
          radius: size.height * 0.1,
          backgroundImage: NetworkImage(photoUrl),
        ),
        SizedBox(height: size.height * 0.03),
        const Text(
          "NOMBRE COMPLETO",
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        Text(
          "${persona['nombre']} ${persona['apellidoPaterno']}",
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: size.height * 0.02),
        const Text(
          "CARNET DE IDENTIDAD",
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        Text(
          "${persona['carnetIdentidad']}",
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
          "HORA DE INGRESO: $hora",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
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
