import 'dart:io';
import 'package:carnetizacion/config/provider/register_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'; // <--- IMPORTANTE PARA USAR kIsWeb
import '../../config/models/selection_models.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep4 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegisterProvider>().fetchUnidadesYCargos(); // <--- NUEVO
    });
  }

  void _nextPage(RegisterProvider provider) {
    if (provider.currentPage < 3) {
      provider.setPage(provider.currentPage + 1);
      _pageController.animateToPage(
        provider.currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage(RegisterProvider provider) {
    if (provider.currentPage > 0) {
      provider.setPage(provider.currentPage - 1);
      _pageController.animateToPage(
        provider.currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop(); // Salir de la pantalla si está en el paso 1
    }
  }

  Future<void> _procesarFoto(
    ImageSource source,
    RegisterProvider provider,
  ) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // 1. Abrir el editor de recorte
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        // Bloqueamos la proporción a 3:4 (Formato Credencial/Retrato)
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
        uiSettings: [
          // Configuración para WEB (Móvil desde el navegador)
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle
                .page, // <--- EL TRUCO ESTÁ AQUÍ (Cambiamos dialog por page)
          ),
          // Configuración para ANDROID (Si instalas la app después)
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Foto para Credencial',
            toolbarColor: const Color(0xFF1E2B5E),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio3x2,
            lockAspectRatio: true, // Obliga a que sea 3:4
            hideBottomControls: false,
          ),
          // Configuración para iOS (Si instalas la app en iPhone)
          IOSUiSettings(title: 'Ajustar Foto', aspectRatioLockEnabled: true),
        ],
      );

      // 2. Si el usuario recortó y aceptó, subimos la imagen final
      if (croppedFile != null) {
        await provider.uploadImage(XFile(croppedFile.path));
      }
    }
  }

  // Títulos dinámicos según el paso
  final List<Map<String, String>> _headers = [
    {
      "title": "Foto del Funcionario",
      "subtitle": "Registro de imagen de perfil.",
    },
    {
      "title": "Datos Personales",
      "subtitle": "Ingrese su información de identificación básica.",
    },
    {"title": "Unidad y Cargo", "subtitle": "Seleccione su ubicación y rol."},
    {
      "title": "Verificación",
      "subtitle": "Confirme su correo y código de seguridad.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegisterProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // --- HEADER AZUL OSCURO ---
          Container(
            padding: const EdgeInsets.only(
              top: 30,
              left: 20,
              right: 20,
              bottom: 40,
            ),
            decoration: const BoxDecoration(color: Color(0xFF1E2B5E)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PASO ${provider.currentPage + 1} DE 4",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _headers[provider.currentPage]["title"]!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _headers[provider.currentPage]["subtitle"]!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 25),
                // Indicador de Progreso
                Row(
                  children: List.generate(4, (index) {
                    Color color;
                    if (index < provider.currentPage) {
                      color = const Color(0xFF4CAF50); // Verde (Completado)
                    } else if (index == provider.currentPage) {
                      color = const Color(0xFFFFD54F); // Amarillo (Actual)
                    } else {
                      color = Colors.white.withOpacity(0.2); // Gris (Pendiente)
                    }
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // --- CONTENIDO BLANCO CURVEADO ---
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Bloquea el swipe manual
                children: [
                  _buildStep1(provider),
                  _buildStep2(provider),
                  _buildStep3(provider),
                  _buildStep4(provider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PASO 1: FOTO DEL FUNCIONARIO
  // ==========================================
  Widget _buildStep1(RegisterProvider provider) {
    // CAMBIO 1: Usamos SingleChildScrollView en lugar de Padding estático
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: provider.imageFile != null
                    // CAMBIO 2: Solución para la web vs Nativo
                    ? ClipOval(
                        child: kIsWeb
                            ? Image.network(
                                provider.imageFile!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(provider.imageFile!.path),
                                fit: BoxFit.cover,
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Sin foto",
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
              ),
              if (provider.isUploadingImage)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                ),
              if (!provider.isUploadingImage)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            "Añada una foto de perfil",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Asegúrese que su rostro esté bien iluminado y centrado para la identificación institucional.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          // CAMBIO 3: Quitamos el Spacer() y ponemos un espacio fijo
          const SizedBox(height: 40),
          _buildPrimaryButton(
            icon: Icons.upload_file,
            text: "Subir Foto",
            onPressed: () => _procesarFoto(ImageSource.gallery, provider),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _procesarFoto(ImageSource.camera, provider),
              icon: const Icon(Icons.camera_alt, color: Colors.black87),
              label: const Text(
                "Tomar Foto",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildNextButton("Siguiente", () {
            if (provider.hasImage) {
              _nextPage(provider);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Por favor suba una foto primero"),
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  // ==========================================
  // PASO 2: DATOS PERSONALES
  // ==========================================
  Widget _buildStep2(RegisterProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField(
              "Nombres",
              "Ej. Juan Alberto",
              Icons.person_outline,
              (v) => provider.nombre = v,
            ),
            _buildInputFieldnorequiered(
              "Apellido Paterno",
              "Ej. Pérez",
              Icons.person_outline,
              (v) => provider.paterno = v,
            ),
            _buildInputFieldnorequiered(
              "Apellido Materno",
              "Ej. García",
              Icons.person_outline,
              (v) => provider.materno = v,
            ),
            _buildInputField(
              "Cédula de Identidad",
              "Ej. 1234567",
              Icons.badge_outlined,
              (v) => provider.ci = v,
            ),
            _buildInputField(
              "Número de Teléfono",
              "Ej. 74312716",
              Icons.phone_outlined,
              (v) => provider.celular = v,
              isNumber: true,
            ),
            const SizedBox(height: 20),
            _buildNextButton("Siguiente", () {
              if (_formKeyStep2.currentState!.validate()) {
                _formKeyStep2.currentState!.save();
                _nextPage(provider);
              }
            }),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PASO 3: UNIDAD Y CARGO
  // ==========================================
  // ==========================================
  // PASO 3: UNIDAD Y CARGO (ACTUALIZADO)
  // ==========================================
  Widget _buildStep3(RegisterProvider provider) {
    // Mostrar loading mientras carga la API
    if (provider.isLoadingData) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Unidad Destinada",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<UnidadItem>(
            decoration: _dropdownDecoration(Icons.domain),
            hint: const Text("Seleccione su unidad"),
            value: provider.selectedUnidad,
            items: provider.unidades
                .map((u) => DropdownMenuItem(value: u, child: Text(u.nombre)))
                .toList(),
            onChanged: (val) {
              setState(() {
                provider.selectedUnidad = val;
                provider.selectedCargo = null; // Reiniciar cargo
                provider.selectedCircunscripcion =
                    null; // Reiniciar circunscripción
              });
            },
          ),
          const SizedBox(height: 25),

          const Text(
            "Cargo Específico",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<CargoItem>(
            decoration: _dropdownDecoration(Icons.work_outline),
            hint: const Text("Seleccione un cargo"),
            value: provider.selectedCargo,
            // Aquí consumimos la lista filtrada mágicamente por el provider
            items: provider.availableCargos
                .map((c) => DropdownMenuItem(value: c, child: Text(c.nombre)))
                .toList(),
            onChanged: (val) {
              setState(() {
                provider.selectedCargo = val;
                provider.selectedCircunscripcion =
                    null; // Reiniciar circunscripción si cambia de cargo
              });
            },
          ),

          if (provider.availableCargos.isEmpty &&
              provider.selectedUnidad != null)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "No hay cargos disponibles para esta unidad.",
                style: TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            ),

          // ==========================================
          // APARICIÓN MÁGICA DE CIRCUNSCRIPCIÓN
          // ==========================================
          if (provider.isNotarioSelected) ...[
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Se requiere especificar el área de asignación.",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Circunscripción (Cochabamba)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: _dropdownDecoration(Icons.map_outlined),
              hint: const Text("Seleccione Circunscripción"),
              value: provider.selectedCircunscripcion,
              items: provider.circunscripcionesCbba
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => provider.selectedCircunscripcion = val),
            ),
          ],

          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "La asignación de unidad y cargo determinará los permisos de acceso en el sistema.",
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          _buildNextButton("Siguiente", () {
            // Lógica de validación dinámica
            bool isValid =
                provider.selectedUnidad != null &&
                provider.selectedCargo != null;
            if (provider.isNotarioSelected &&
                provider.selectedCircunscripcion == null) {
              isValid = false;
            }

            if (isValid) {
              _nextPage(provider);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Complete todos los campos requeridos"),
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  // ==========================================
  // PASO 4: VERIFICACIÓN FINAL
  // ==========================================
  Widget _buildStep4(RegisterProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Form(
        key: _formKeyStep4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Correo Electrónico",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _inputDecoration(
                      "ej. juan@institucion.gob",
                      Icons.email_outlined,
                    ),
                    onSaved: (v) => provider.correo = v!,
                    validator: (v) => v!.isEmpty || !v.contains('@')
                        ? 'Correo inválido'
                        : null,
                  ),
                ),
                TextButton(
                  onPressed: provider.isRequestingCode
                      ? null
                      : () async {
                          if (_formKeyStep4.currentState!.validate()) {
                            _formKeyStep4.currentState!.save();
                            bool success = await provider.solicitarCodigo();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Código enviado a su correo"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                  child: provider.isRequestingCode
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Enviar código",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              "Enviaremos un código de 6 dígitos a este correo.",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 30),

            const Text(
              "Código de Verificación",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // Input de código estilo PIN simple
            TextFormField(
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (v) => provider.codigoVerificacion = v,
            ),

            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified_user, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Al finalizar el registro, su cuenta quedará pendiente de aprobación por parte de Recursos Humanos.",
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildPrimaryButton(
              icon: Icons.check_circle,
              text: "Finalizar Registro",
              isLoading: provider.isSubmitting,
              onPressed: () async {
                if (provider.codigoVerificacion.length == 6) {
                  bool success = await provider.registrarPersonal();
                  if (success && context.mounted) {
                    // Llamamos a nuestro nuevo diálogo de éxito
                    _mostrarDialogoExito(context, provider);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ingrese el código de 6 dígitos"),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANTALLA DE ÉXITO (DIÁLOGO)
  // ==========================================
  void _mostrarDialogoExito(BuildContext context, RegisterProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga al usuario a presionar "Terminar"
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(30),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                "¡Registro Exitoso!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2B5E),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "El personal ha sido registrado correctamente y está pendiente de aprobación por Recursos Humanos.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // 1. Cerramos el diálogo flotante
                    Navigator.of(ctx).pop();

                    // 2. Limpiamos todas las variables de la memoria
                    provider.resetForm();

                    // 3. Limpiamos visualmente los campos de texto
                    _formKeyStep2.currentState?.reset();
                    _formKeyStep4.currentState?.reset();

                    // 4. Movemos la pantalla de vuelta al Paso 1
                    _pageController.jumpToPage(0);
                  },
                  child: const Text(
                    "Terminar",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // --- WIDGETS DE APOYO (Para no repetir código) ---

  Widget _buildInputField(
    String label,
    String hint,
    IconData icon,
    Function(String) onSaved, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: _inputDecoration(hint, icon),
            validator: (v) => v!.isEmpty ? 'Requerido' : null,
            onSaved: (v) => onSaved(v!),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFieldnorequiered(
    String label,
    String hint,
    IconData icon,
    Function(String) onSaved, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: _inputDecoration(hint, icon),

            onSaved: (v) => onSaved(v!),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
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
    );
  }

  InputDecoration _dropdownDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildNextButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD54F), // Amarillo
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? const SizedBox.shrink() : Icon(icon),
        label: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.black87,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD54F),
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
