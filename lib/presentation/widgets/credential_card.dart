import 'package:flutter/material.dart';
import '../../config/models/employee_model.dart';

class CredentialCard extends StatelessWidget {
  final Employee employee;
  final bool isBack;

  const CredentialCard({
    super.key,
    required this.employee,
    this.isBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.58,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isBack ? _buildBack() : _buildFront(),
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/card_template_front.png',
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 45,
          left: 30,
          child: Container(
            width: 105,
            height: 105,
            color: Colors.white,
            child: Image.network(employee.qrUrl),
          ),
        ),

        Positioned(
          top: 160,
          left: 95,
          child: Image.asset('assets/images/logo_ted.png', width: 30),
        ),

        Positioned(
          top: 45,
          right: 45,
          child: Container(
            width: 80,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                employee.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => const Icon(Icons.person),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 40,
          right: 10,
          width: 160,
          child: Column(
            children: [
              Text(
                "Ci: ${employee.ci}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              // AQUÍ USAMOS TU GETTER nombreCompleto
              Text(
                employee.nombreCompleto,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  height: 1.1,
                ),
              ),
              Text(
                employee.cargo,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 6),
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 35,
          left: 10,
          child: Image.asset('assets/images/logo_elecciones.png', width: 65),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 25,
          child: Container(
            color: const Color(0xFF222222),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Personal Eventual",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Elecciones subnacionales 2026",
                  style: TextStyle(color: Colors.white, fontSize: 7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBack() {
    return Image.asset(
      'assets/images/ATRAS_EVENTUAL_2025.png',
      fit: BoxFit.cover,
    );
  }
}
