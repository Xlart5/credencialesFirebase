import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // 🔥 Importante para leer el AuthProvider

import '../../config/provider/auth_provider.dart'; // 🔥 Importamos tu AuthProvider

import 'package:carnetizacion/presentation/screens/computo_screen.dart';
import 'package:carnetizacion/presentation/screens/login_screen.dart';
import 'package:carnetizacion/presentation/screens/monitor_screen.dart';
import 'package:carnetizacion/presentation/screens/reports_screen.dart';
import 'package:carnetizacion/presentation/screens/unidades_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/success_screen.dart';
import '../../presentation/screens/print_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',

  redirect: (context, state) {
    // 1. Consultamos el estado de autenticación
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;

    // 2. Detectamos si es un dispositivo móvil (Android o iOS)
    final isMobileDevice =
        (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

    // 3. Vemos a qué ruta intenta acceder
    final isGoingToRegister =
        state.matchedLocation == '/register'; // 🔥 Typo corregido
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToSuccess = state.matchedLocation.startsWith('/success');

    // --- REGLAS ESTRICTAS PARA MÓVIL ---
    if (isMobileDevice) {
      // Si es MÓVIL, solo puede estar en Registro o en Success.
      if (!isGoingToRegister && !isGoingToSuccess) {
        return '/registro';
      }
      return null; // Lo dejamos pasar a registro o success
    }
    // --- REGLAS ESTRICTAS PARA PC ---
    else {
      // Si intenta entrar al registro desde PC...
      if (isGoingToRegister || isGoingToSuccess) {
        return '/login'; // ... lo rebotamos
      }

      // 🔥 SEGURIDAD: Si NO está logueado y trata de ir a cualquier pantalla que no sea login
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      // Si YA está logueado pero intenta volver a la pantalla de Login
      if (isLoggedIn && isGoingToLogin) {
        return '/'; // Lo mandamos directo al Dashboard
      }
    }

    // Si pasó todas las validaciones de seguridad, lo dejamos navegar.
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
