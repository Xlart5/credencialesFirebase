import 'package:carnetizacion/presentation/screens/computo_screen.dart';
import 'package:carnetizacion/presentation/screens/login_screen.dart';
import 'package:carnetizacion/presentation/screens/monitor_screen.dart';
import 'package:carnetizacion/presentation/screens/reports_screen.dart';
import 'package:carnetizacion/presentation/screens/unidades_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/success_screen.dart';
import '../../presentation/screens/print_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',

  redirect: (context, state) {
    // 1. Detectamos si es un dispositivo móvil (Android o iOS)
    final isMobileDevice =
        (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

    // 2. Vemos a qué ruta intenta acceder
    final isGoingToRegister = state.matchedLocation == '/register';

    // --- REGLAS ESTRICTAS ---

    if (isMobileDevice) {
      // Si es MÓVIL y está intentando entrar al Login, Dashboard, o cualquier otra cosa...
      if (!isGoingToRegister) {
        return '/registro'; // ... lo forzamos a ir ÚNICAMENTE al registro.
      }
    } else {
      // Si es PC y está intentando entrar a la pantalla de Registro móvil...
      if (isGoingToRegister) {
        return '/login'; // ... lo rebotamos al Login.
      }
    }

    // Si está en PC y va a PC, o está en Móvil y va a Móvil, lo dejamos pasar.
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegisterScreen(),
    ),

    GoRoute(
      path: '/success',
      builder: (context, state) {
        final id = state.extra as String?;
        return SuccessScreen(registerId: id);
      },
    ),

    GoRoute(
      path: '/impresion',
      builder: (context, state) => const PrintScreen(),
    ),

    GoRoute(
      path: '/unidades',
      builder: (context, state) => const UnidadesScreen(),
    ),
    GoRoute(
      path: '/computo',
      builder: (context, state) => const ComputoScreen(),
    ),
    GoRoute(
      path: '/acceso',
      builder: (context, state) => const MonitorScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/reportes',
      name: 'reportes', // Nombre opcional para usar pushNamed
      builder: (context, state) => const ReportsScreen(),
    ),
  ],
);
