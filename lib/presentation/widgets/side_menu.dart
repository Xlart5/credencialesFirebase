import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/provider/auth_provider.dart';
import '../../config/theme/app_colors.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  bool _esConsulta = false;

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

  Future<void> _cargarRol() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _esConsulta = prefs.getString('rol') == 'CONSULTA';
    });
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // --- HEADER (LOGO) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.how_to_vote,
                    color: AppColors.primaryDark,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "SISTEMA TED",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  "Gestión Electoral",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- LISTA DE NAVEGACIÓN ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  text: "Dashboard",
                  isActive: location == '/',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                ),
                
                if (!_esConsulta)
                  _DrawerItem(
                    icon: Icons.person_add_alt_1_outlined,
                    text: "Unidades y Cargos",
                    isActive: location == '/Unidades',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/Unidades');
                    },
                  ),
                  
                if (!_esConsulta)
                  _DrawerItem(
                    icon: Icons.print_outlined,
                    text: "Impresión Credenciales",
                    isActive: location == '/impresion',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/impresion');
                    },
                  ),
                  
                _DrawerItem(
                  icon: Icons.workspace_premium,
                  text: "Certificados",
                  isActive: location == '/certificados',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/certificados');
                  },
                ),
                
                if (!_esConsulta)
                  _DrawerItem(
                    icon: Icons.qr_code,
                    text: "Generar QRs Externos",
                    isActive: location == '/generar-Externos', 
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/generar-Externos');
                    },
                  ),

                if (!_esConsulta) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 10, left: 15),
                    child: Text(
                      "MONITORES DE PUERTA",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  _DrawerItem(
                    icon: Icons.badge_outlined,
                    text: "Monitor Eventuales",
                    isActive: location == '/acceso/eventuales',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/acceso/eventuales');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.login_rounded,
                    text: "Externos - Ingreso",
                    isActive: location == '/acceso/externos/ingreso',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/acceso/externos/ingreso');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    text: "Externos - Salida",
                    isActive: location == '/acceso/externos/salida',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/acceso/externos/salida');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    text: "Historial de Acceso",
                    isActive: location == '/acceso/Historial',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/acceso/Historial');
                    },
                  ),

                  const Divider(height: 30), 
                  
                  _DrawerItem(
                    icon: Icons.computer_outlined,
                    text: "Acceso a Cómputo",
                    isActive: location == '/computo',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/computo');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.text_snippet_rounded,
                    text: "Reportes",
                    isActive: location == '/reportes',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/reportes'); 
                    },
                  ),
                ]
              ],
            ),
          ),

          // --- FOOTER (BOTÓN LOGOUT) ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: () async {
                await context.read<AuthProvider>().logout();

                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/login');
                }
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50, 
                  border: Border.all(color: Colors.red.shade200, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: const [
                      Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        "Desconectarse",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryYellow.withOpacity(0.8)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.textDark : Colors.grey[600],
          size: 22,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isActive ? AppColors.textDark : Colors.grey[700],
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13, 
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }
}