import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart'; // Para la fecha (opcional, o usa DateTime)
import '../../config/theme/app_colors.dart';

class SuccessScreen extends StatefulWidget {
  final String? registerId; // Recibimos el ID generado o aleatorio

  const SuccessScreen({super.key, this.registerId});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  Widget build(BuildContext context) {
    // Generamos datos simulados si no vienen
    final String displayId = widget.registerId ?? "#REG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    final String dateStr = "Hoy, ${DateFormat('hh:mm a').format(DateTime.now())}";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 450, // Ancho limitado para que parezca una tarjeta centrada
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
             
              SizedBox(
                height: 150,
                width: 150,
                child: Icon(Icons.check_circle_outline,color: Colors.green,size: 90,
  ),
              ),
              const SizedBox(height: 20),

              // 2. TÍTULOS
              const Text(
                "¡Registro Exitoso!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Los datos del empleado han sido validados y almacenados correctamente en la base de datos institucional.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // 3. BADGES DE INFORMACIÓN (ID y Fecha)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInfoBadge(Icons.dns, "ID: $displayId"),
                  const SizedBox(width: 15),
                  _buildInfoBadge(Icons.access_time_filled, dateStr),
                ],
              ),

              const SizedBox(height: 40),

              // 4. BOTÓN DE CONTINUAR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Volver al Dashboard y limpiar el historial de navegación
                    context.go('/'); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "VOLVER AL INICIO",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background, // Color gris suave de fondo
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.successGreen), // Icono verde
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}