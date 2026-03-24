import 'package:carnetizacion/presentation/screens/certificados_masivo_screen.dart';
import 'package:carnetizacion/presentation/screens/certificados_screen.dart';
import 'package:carnetizacion/presentation/screens/generar_qrs_screen.dart';
import 'package:carnetizacion/presentation/screens/historial_screen.dart';
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
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;
    final isMobileDevice = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    // 🔥 Usamos state.uri.path que es 100% exacto
    final path = state.uri.path;

    final isGoingToPublicRegister = path == '/registro' || path == '/registro/planta';
    final isGoingToAdminRegister = path == '/registro-admin' || path == '/registro-admin/planta';
    final isGoingToLogin = path == '/login';
    final isGoingToSuccess = path.startsWith('/success');

    // --- REGLAS ESTRICTAS PARA MÓVIL ---
    if (isMobileDevice) {
      if (!isGoingToPublicRegister && !isGoingToSuccess) {
        return '/registro';
      }
      return null;
    }
    // --- REGLAS ESTRICTAS PARA PC ---
    else {
      if (isGoingToPublicRegister || isGoingToSuccess) {
        return '/login';
      }
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }
      if (isLoggedIn && isGoingToLogin) {
        return '/'; 
      }
    }
    return null;
  },

  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),

    // --- RUTAS PÚBLICAS (Móvil) ---
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegisterScreen(esPlanta: false),
    ),
    GoRoute(
      path: '/registro/planta',
      builder: (context, state) => const RegisterScreen(esPlanta: true),
    ),

    // --- RUTAS PRIVADAS ADMINISTRATIVAS (PC) ---
    GoRoute(
      path: '/registro-admin',
      builder: (context, state) => const RegisterScreen(esPlanta: false),
    ),
    GoRoute(
      path: '/registro-admin/planta',
      builder: (context, state) => const RegisterScreen(esPlanta: true),
    ),

    GoRoute(
      path: '/success',
      builder: (context, state) {
        final id = state.extra as String?;
        return SuccessScreen(registerId: id);
      },
    ),
    GoRoute(path: '/impresion', builder: (context, state) => const PrintScreen()),
    GoRoute(path: '/unidades', builder: (context, state) => const UnidadesScreen()),
    GoRoute(path: '/computo', builder: (context, state) => const ComputoScreen()),
    GoRoute(
      path: '/acceso/externos/ingreso',
      builder: (context, state) => const MonitorScreen(tipoPuerta: 'externos_entrada'),
    ),
    GoRoute(
      path: '/acceso/externos/salida',
      builder: (context, state) => const MonitorScreen(tipoPuerta: 'externos_salida'),
    ),
    GoRoute(
      path: '/acceso/eventuales',
      builder: (context, state) => const MonitorScreen(tipoPuerta: 'eventuales'),
    ),
    GoRoute(path: '/acceso/Historial', builder: (context, state) => const HistorialScreen()),
    GoRoute(path: '/generar-Externos', builder: (context, state) => const GenerarQrsScreen()),
    GoRoute(path: '/certificados', builder: (context, state) => const CertificadosScreen()),
    GoRoute(path: '/certificados-masivo', builder: (context, state) => const CertificadosMasivoScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/reportes',
      name: 'reportes',
      builder: (context, state) => const ReportsScreen(),
    ),
  ],
);