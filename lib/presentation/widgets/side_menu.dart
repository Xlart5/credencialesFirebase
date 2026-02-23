import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Detectamos la ruta actual para resaltar el botón activo
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
                    Navigator.pop(context); // Cerrar drawer primero
                    context.go('/');
                  },
                ),
                _DrawerItem(
                  icon: Icons.person_add_alt_1_outlined,
                  text: "Gestionar Unidades/Cargos",
                  isActive: location == '/Unidades',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/Unidades');
                  },
                ),
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
                  icon: Icons.print_outlined,
                  text: "Acceso",
                  isActive: location == '/acceso',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/acceso');
                  },
                ),
                _DrawerItem(
                  icon: Icons.text_snippet_rounded,
                  text: "Reporte",
                  isActive: location == '/reportes',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/reportes');
                  },
                ),
                const Divider(height: 30), // Separador visual
                _DrawerItem(
                  icon: Icons.computer_outlined,
                  text: "Acceso a Cómputo",
                  isActive: location == '/computo',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/computo');
                  },
                ),
              ],
            ),
          ),

          // --- FOOTER ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 10),
                Text(
                  "Admin Verificado",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryYellow : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.textDark : Colors.grey[600],
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isActive ? AppColors.textDark : Colors.grey[700],
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }
}
