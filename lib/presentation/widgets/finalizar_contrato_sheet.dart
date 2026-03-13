import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/models/employee_model.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';

void showFinalizarContratoSheet(BuildContext context, Employee emp) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FinalizarContratoSheet(employee: emp),
  );
}

class FinalizarContratoSheet extends StatefulWidget {
  final Employee employee;
  const FinalizarContratoSheet({super.key, required this.employee});

  @override
  State<FinalizarContratoSheet> createState() => _FinalizarContratoSheetState();
}

class _FinalizarContratoSheetState extends State<FinalizarContratoSheet> {
  DateTime? _fechaIngreso;
  DateTime? _fechaFin;
  bool _isProcessing = false;

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: esInicio
          ? "Seleccionar Fecha de Inicio"
          : "Seleccionar Fecha de Finalización",
    );
    if (seleccion != null) {
      setState(
        () => esInicio ? _fechaIngreso = seleccion : _fechaFin = seleccion,
      );
    }
  }

  Future<void> _guardarYFinalizar() async {
    if (_fechaIngreso == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Es obligatorio ingresar ambas fechas"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // 🔥 Ejecutamos el cierre. El provider se encarga de borrar a la persona de la lista local.
    bool success = await context
        .read<EmployeeProvider>()
        .registrarFechasProceso(widget.employee.id, _fechaIngreso!, _fechaFin!);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Contrato finalizado exitosamente"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al cerrar contrato."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
      ),
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
                      Icons.assignment_turned_in,
                      color: AppColors.primaryYellow,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Finalizar Contrato\n${widget.employee.nombreCompleto}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                child: Column(
                  children: [
                    const Text(
                      "Defina el periodo trabajado para cerrar el contrato actual. Estos datos se reflejarán en el certificado.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Fecha Inicio",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _seleccionarFecha(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _fechaIngreso != null
                                          ? format.format(_fechaIngreso!)
                                          : "Seleccionar",
                                      style: TextStyle(
                                        color: _fechaIngreso != null
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Fecha Fin",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _seleccionarFecha(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _fechaFin != null
                                          ? format.format(_fechaFin!)
                                          : "Seleccionar",
                                      style: TextStyle(
                                        color: _fechaFin != null
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _guardarYFinalizar,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lock_outline),
                        label: Text(
                          _isProcessing
                              ? "Procesando..."
                              : "CERRAR CONTRATO AHORA",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
