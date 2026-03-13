import 'package:carnetizacion/presentation/screens/certificados_masivo_screen.dart';
import 'package:carnetizacion/presentation/screens/certificados_screen.dart';
import 'package:carnetizacion/presentation/screens/generar_qrs_screen.dart';
import 'package:carnetizacion/presentation/screens/monitor_externo_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/provider/auth_provider.dart';

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

    // 3. Identificamos a qué ruta intenta acceder
    // 🔥 CORRECCIÓN: Cambié '/register' por '/registro' para que coincida con tu ruta real pública
    final isGoingToPublicRegister = state.matchedLocation == '/registro';
    final isGoingToAdminRegister =
        state.matchedLocation == '/registro-admin'; // 🔥 NUEVA RUTA PRIVADA
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToSuccess = state.matchedLocation.startsWith('/success');

    // --- REGLAS ESTRICTAS PARA MÓVIL ---
    if (isMobileDevice) {
      // Si es MÓVIL, solo puede estar en Registro Público o en Success.
      if (!isGoingToPublicRegister && !isGoingToSuccess) {
        return '/registro';
      }
      return null;
    }
    // --- REGLAS ESTRICTAS PARA PC ---
    else {
      // Si intenta entrar al registro PÚBLICO desde PC...
      if (isGoingToPublicRegister || isGoingToSuccess) {
        return '/login'; // ... lo rebotamos
      }

      // 🔥 SEGURIDAD: Si NO está logueado y trata de ir a cualquier pantalla que no sea login
      // (Esto protege automáticamente la nueva ruta '/registro-admin' exigiendo sesión)
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

    // --- RUTA PÚBLICA (Móvil) ---
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegisterScreen(),
    ),

    // --- 🔥 RUTA PRIVADA ADMINISTRATIVA (PC) ---
    GoRoute(
      path: '/registro-admin',
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
      path: '/acceso/externos/ingreso',
      builder: (context, state) =>
          const MonitorScreen(tipoPuerta: 'externos_entrada'),
    ),
    GoRoute(
      path: '/acceso/externos/salida',
      builder: (context, state) =>
          const MonitorScreen(tipoPuerta: 'externos_salida'),
    ),
    GoRoute(
      path: '/acceso/eventuales',
      builder: (context, state) =>
          const MonitorScreen(tipoPuerta: 'eventuales'),
    ),
    GoRoute(
      path: '/generar-Externos',
      builder: (context, state) => const GenerarQrsScreen(),
    ),
    GoRoute(
      path: '/certificados',
      builder: (context, state) => const CertificadosScreen(),
    ),
    GoRoute(
      path: '/certificados-masivo',
      builder: (context, state) => const CertificadosMasivoScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/reportes',
      name: 'reportes',
      builder: (context, state) => const ReportsScreen(),
    ),
  ],
);
