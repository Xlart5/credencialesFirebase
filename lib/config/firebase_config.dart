import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart'; // Ajusta los '../' si firebase_options.dart está en otra carpeta

class FirebaseConfig {
  static Future<void> init() async {
    // Usamos las opciones automáticas que FlutterFire generó para ti
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}