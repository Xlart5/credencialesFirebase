import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/models/employee_model.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';
import 'nuevo_contrato_sheet.dart'; // 🔥 Importamos tu sheet de POST

void showModalEvaluarContrato(BuildContext context, Employee emp) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ModalEvaluarContrato(employee: emp),
  );
}

class ModalEvaluarContrato extends StatefulWidget {
  final Employee employee;
  const ModalEvaluarContrato({super.key, required this.employee});

  @override
  State<ModalEvaluarContrato> createState() => _ModalEvaluarContratoState();
}

class _ModalEvaluarContratoState extends State<ModalEvaluarContrato> {
  DateTime? _fechaIngreso;
  DateTime? _fechaFin;
  bool _isProcessing = false;

  bool _isLoadingHistory = true;
  bool _tieneContratoActivo = false;

  @override
  void initState() {
    super.initState();
    _verificarHistorial();
  }

  // 🔥 ESTO EVITA EL ERROR 404. Preguntamos al backend antes de mostrar botones.
  Future<void> _verificarHistorial() async {
    final provider = context.read<EmployeeProvider>();
    final historial = await provider.obtenerHistorialPersonal(
      widget.employee.id,
    );

    if (mounted) {
      setState(() {
        _tieneContratoActivo = historial.any((h) => h['activo'] == true);
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (seleccion != null)
      setState(
        () => esInicio ? _fechaIngreso = seleccion : _fechaFin = seleccion,
      );
  }

  Future<void> _guardarYFinalizar() async {
    if (_fechaIngreso == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seleccione ambas fechas"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isProcessing = true);
    final provider = context.read<EmployeeProvider>();
    bool success = await provider.registrarFechasProceso(
      widget.employee.id,
      _fechaIngreso!,
      _fechaFin!,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "Contrato Cerrado y Fechas Guardadas"
                : "Error al guardar fechas",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.manage_search,
                      color: AppColors.primaryYellow,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Evaluación de Contrato\n${widget.employee.nombre}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(25.0),
                child: _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator())
                    : _tieneContratoActivo
                    // ========================================================
                    // ESCENARIO A: SÍ TIENE CONTRATO ACTIVO -> PEDIR FECHAS
                    // ========================================================
                    ? Column(
                        children: [
                          const Text(
                            "Esta persona tiene un contrato activo. Defina el periodo de trabajo para cerrarlo definitivamente.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _seleccionarFecha(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _fechaIngreso != null
                                          ? format.format(_fechaIngreso!)
                                          : "Inicio",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      _seleccionarFecha(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _fechaFin != null
                                          ? format.format(_fechaFin!)
                                          : "Fin",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              onPressed: _isProcessing
                                  ? null
                                  : _guardarYFinalizar,
                              child: Text(
                                _isProcessing
                                    ? "Procesando..."
                                    : "Guardar y Cerrar Contrato",
                              ),
                            ),
                          ),
                        ],
                      )
                    // ========================================================
                    // ESCENARIO B: NO TIENE ACTIVO -> INICIAR NUEVO CONTRATO
                    // ========================================================
                    : Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 50,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            "Esta persona NO tiene ningún contrato activo en este momento. Ya fue cerrado.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context); // Cierra este modal
                                showNuevoContratoSheet(
                                  context,
                                  widget.employee,
                                ); // Abre tu POST modal
                              },
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text("Iniciar Nuevo Contrato"),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
