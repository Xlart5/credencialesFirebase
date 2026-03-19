import 'package:carnetizacion/config/provider/externos_provider.dart';
import 'package:carnetizacion/config/provider/historial_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 IMPORTANTE

// Importaciones de Providers
import 'config/provider/auth_provider.dart';
import 'config/provider/employee_provider.dart';
import 'config/provider/register_provider.dart';
import 'config/provider/unidades_provider.dart';

// Importaciones de configuración y rutas
import 'config/router/app_router.dart';
import 'config/theme/app_colors.dart';
import 'config/firebase_config.dart';
import 'config/constans/constants/environment.dart'; // 🔥 IMPORTANTE

void main() async {
  // 1. LÍNEA VITAL: Obligatoria en Flutter antes de arrancar configuraciones nativas
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos Firebase (Si aún lo usas para otras cosas)
  await FirebaseConfig.init();

  // 🔥 3. MAGIA ANTI-F5: RECUPERAMOS SESIÓN DEL DISCO DURO
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('jwt_token');
  final savedUserData = prefs.getString('user_data');

  // Creamos la instancia del AuthProvider aquí mismo
  final authProvider = AuthProvider();

  // Si hay datos guardados, restauramos la sesión antes de que la app se dibuje
  if (savedToken != null && savedUserData != null) {
    authProvider.restaurarSesion(savedToken, savedUserData);
  }

  // 4. Arrancamos la App pasándole el Provider ya configurado
  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider; // Recibimos el AuthProvider hidratado

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    // MultiProvider permite inyectar múltiples estados
    return MultiProvider(
      providers: [
        // 🔥 Usamos .value porque ya creamos la instancia en el main()
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        ChangeNotifierProvider(create: (_) => UnidadesProvider()),
         ChangeNotifierProvider(create: (_) => HistorialProvider()),
        ChangeNotifierProvider(create: (context) => ExternosProvider()),
      ],
      child: MaterialApp.router(
        title: 'Control Central TED',
        debugShowCheckedModeBanner: false,

        // Configuración de rutas (GoRouter)
        routerConfig: appRouter,

        // Tema Global
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryYellow),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,

          // Estilo global de inputs para ahorrar código en pantallas
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }
}
