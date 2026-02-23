import 'package:carnetizacion/config/helpers/pdf_generator_service.dart';
import 'package:carnetizacion/config/provider/employee_provider.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../widgets/kpi_card.dart';
import '../widgets/sidebar_filter.dart';
import '../widgets/employees_table.dart';
import '../widgets/side_menu.dart'; // <--- ASEGÚRATE DE TENER ESTE IMPORT

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // CLAVE PARA PODER ABRIR EL DRAWER
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    return Scaffold(
      key: _scaffoldKey, // <--- VINCULAMOS LA CLAVE AQUÍ
      backgroundColor: AppColors.background,
      floatingActionButton: provider.selectedForPrint.isEmpty
          ? null // Desaparece si no hay seleccionados
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primaryYellow,
              icon: const Icon(Icons.print, color: Colors.black),
              label: Text(
                "Imprimir Lote (${provider.selectedForPrint.length})",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final seleccionados = provider.selectedForPrint.toList();

                // Generamos el PDF con todos los seleccionados
                final pdfBytes =
                    await PdfGeneratorService.generateCredentialsPdf(
                      seleccionados,
                    );

                await Printing.layoutPdf(
                  onLayout: (format) async => pdfBytes,
                  name:
                      'Lote_Personalizado_${DateTime.now().millisecondsSinceEpoch}.pdf',
                );

                // Limpiamos la selección después de imprimir
                provider.clearSelection();
              },
            ),

      drawer: const SideMenu(),

      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TÍTULOS IZQUIERDA
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "CONTROL CENTRAL",
                      style: TextStyle(
                        letterSpacing: 2,
                        fontSize: 12,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Panel de Administración",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),

                // ZONA DERECHA: Notificaciones + Botón Admin
                Row(
                  children: [
                    // Icono Notificación
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: AppColors.primaryDark,
                      ),
                    ),

                    const SizedBox(width: 20),

                    // BOTÓN ADMINISTRADOR (ESTILO PERSONALIZADO)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // ABRIR EL DRAWER
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 6,
                            top: 6,
                            bottom: 6,
                            right: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icono cuadrado oscuro
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1A1F24,
                                  ), // Negro/Gris oscuro
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Texto
                              const Text(
                                "Administrador",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- 2. TARJETAS KPI ---
            Row(
              children: [
                KPICard(
                  title: "TOTAL",
                  value: provider.totalEmployees.toString(),
                  subtitle: "Empleados registrados",
                  icon: Icons.people_alt_outlined,
                  badgeText: "TOTAL",
                ),
                KPICard(
                  title: "ÉXITO",
                  value: provider.printedCredentials.toString(),
                  subtitle: "Credenciales Impresas",
                  icon: Icons.print_outlined,
                  isDark: true,
                  badgeText: "IMPRESOS",
                ),
                KPICard(
                  title: "REVISIÓN",
                  value: provider.pendingRequests.toString(),
                  subtitle: "Solicitudes pendientes",
                  icon: Icons.assignment_late_outlined,
                  badgeText: "PENDIENTES",
                ),
              ],
            ),

            // --- 3. TABLA DE DATOS ---
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SidebarFilter(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: SingleChildScrollView(child: EmployeesTable()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
