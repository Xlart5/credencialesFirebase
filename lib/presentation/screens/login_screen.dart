import 'package:carnetizacion/config/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _recuerdame = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese sus credenciales'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    // Llamamos a la API
    final success = await authProvider.login(username, password, _recuerdame);

    if (success) {
      if (context.mounted) {
        // Redirigir al Panel Administrativo
        context.go('/');
      }
    } else {
      if (context.mounted) {
        // Mostrar error si falla
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el proveedor solo para saber si está cargando y deshabilitar/cambiar el botón
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Row(
        children: [
          // --- LEFT PANEL (DARK BLUE) ---
          Flexible(
            flex: 2,
            child: Container(
              color: const Color(0xFF1E2A4F),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: Image.network(
                                "assets/images/logo_ted.png",
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Center(
                          child: Text(
                            "Tribunal Electoral Departamental",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            "Optimice sus procesos administrativos, gestione unidades y potencie su capital humano con la plataforma integral de InstiManage.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "V. 2.4.0",
                          style: TextStyle(color: Colors.white54),
                        ),
                        Text(
                          "Sistema Certificado",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- RIGHT PANEL (WHITE) ---
          Flexible(
            flex: 3,
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: Center(
                child: Card(
                  elevation: 5,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: 450,
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.security, color: Colors.amber, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "ACCESO SEGURO",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Bienvenido",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Ingrese sus credenciales para acceder al sistema",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 30),

                        // FORM
                        _buildTextField(
                          label: "Usuario o Correo Electrónico",
                          icon: Icons.person_outline,
                          hint: "admin",
                          controller: _userCtrl,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: "Contraseña",
                          icon: Icons.lock_outline,
                          hint: "••••••••",
                          obscureText: true,
                          controller: _passCtrl,
                        ),
                        const SizedBox(height: 20),

                        // CHECKBOX
                        Row(
                          children: [
                            Checkbox(
                              value: _recuerdame,
                              activeColor: Colors.amber,
                              onChanged: (value) =>
                                  setState(() => _recuerdame = value!),
                            ),
                            const Text(
                              "Recuérdame",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            // Deshabilitamos el botón si está cargando
                            onPressed: authProvider.isLoading
                                ? null
                                : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: const Color(0xFF1E2A4F),
                              disabledBackgroundColor: Colors.amber.withOpacity(
                                0.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1E2A4F),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.login),
                                      SizedBox(width: 8),
                                      Text(
                                        "Iniciar Sesión",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              "¿Olvidaste tu contraseña?",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amber),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
    );
  }

  Widget _buildFooterSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Text("•", style: TextStyle(color: Colors.grey)),
    );
  }
}
