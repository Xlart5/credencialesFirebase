import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Importaciones de Providers
import 'config/provider/auth_provider.dart';
import 'config/provider/employee_provider.dart';
import 'config/provider/register_provider.dart';
import 'config/provider/unidades_provider.dart';

// Importaciones de configuración y rutas
import 'config/router/app_router.dart';
import 'config/theme/app_colors.dart';
import 'config/firebase_config.dart'; // 🔥 Importamos tu nuevo archivo

void main() async {
  // 1. LÍNEA VITAL: Obligatoria en Flutter antes de arrancar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos Firebase limpiamente
  await FirebaseConfig.init();

  // 3. Arrancamos la App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider permite inyectar múltiples estados en la cima del árbol de widgets
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        ChangeNotifierProvider(create: (_) => UnidadesProvider()),
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