import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../config/models/employee_model.dart';
import '../../config/provider/employee_provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/helpers/certificate_pdf_service.dart';

void showCertificadoSheet(BuildContext context, Employee emp) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CertificadoSheet(employee: emp),
  );
}

class CertificadoSheet extends StatefulWidget {
  final Employee employee;
  const CertificadoSheet({super.key, required this.employee});

  @override
  State<CertificadoSheet> createState() => _CertificadoSheetState();
}

class _CertificadoSheetState extends State<CertificadoSheet> {
  DateTime? _fechaIngreso;
  DateTime? _fechaFin;
  bool _isProcessing = false;
  bool _isLoadingHistory = false;

  // Variables para guardar los datos de Firebase si existen
  String _cargoDescripcion = "Servicio de Terceros";
  String _tipoContrato = "Administrativo I";
  String _cargoNombre = "";

  bool get _estaDevuelto =>
      widget.employee.estadoActual.toUpperCase() == 'CREDENCIAL DEVUELTO';
  bool get _estaTerminado =>
      widget.employee.estadoActual.toUpperCase() == 'CONTRATO TERMINADO';

  @override
  void initState() {
    super.initState();
    _cargoNombre = widget.employee.cargo;
    if (_estaTerminado) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _cargarUltimoHistorial());
    }
  }

  Future<void> _cargarUltimoHistorial() async {
    setState(() => _isLoadingHistory = true);
    final provider = context.read<EmployeeProvider>();
    
    // Primero intentamos buscar en Firebase para obtener los datos enriquecidos
    final contratosFirebase = await provider.obtenerContratosDePersonaFirebase(widget.employee.id.toString());
    
    if (contratosFirebase.isNotEmpty) {
      final ultimo = contratosFirebase.first; // En Firebase el más reciente suele estar de primero por el orderBy
      setState(() {
        _fechaIngreso = DateTime.parse(ultimo['fechaInicio']);
        _fechaFin = DateTime.parse(ultimo['fechaFin']);
        _cargoNombre = ultimo['cargo'] ?? widget.employee.cargo;
        _cargoDescripcion = ultimo['cargoDescripcion'] ?? "Servicio de Terceros";
        _tipoContrato = ultimo['tipoContrato'] ?? "Administrativo I";
        _isLoadingHistory = false;
      });
      return;
    }

    // Si no está en Firebase, buscamos en el historial normal de Spring Boot
    final historial = await provider.obtenerHistorialPersonal(widget.employee.id);
    if (historial.isNotEmpty) {
      final ultimo = historial.last;
      setState(() {
        _fechaIngreso = DateTime.parse(ultimo['fechaInicio']);
        _fechaFin = DateTime.parse(ultimo['fechaFin']);
        _isLoadingHistory = false;
      });
    } else {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    if (_estaTerminado) return; 
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (seleccion != null) {
      setState(() => esInicio ? _fechaIngreso = seleccion : _fechaFin = seleccion);
    }
  }

  Future<void> _guardarYFinalizar() async {
    if (_fechaIngreso == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar ambas fechas primero"), backgroundColor: Colors.orange),
      );
      return;
    }

    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Cerrar Contrato?"),
        content: const Text("Se guardarán las fechas y se cerrará el contrato activo de esta persona."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmar) return;
    setState(() => _isProcessing = true);

    try {
      final provider = context.read<EmployeeProvider>();
      bool success = await provider.registrarFechasProceso(widget.employee.id, _fechaIngreso!, _fechaFin!);

      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contrato terminado exitosamente"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar en el servidor"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 🔥 SOLUCIÓN DEL ERROR AQUÍ: Usar el nuevo formato de CertificadoData
  Future<void> _imprimirCertificado() async {
    if (_fechaIngreso == null || _fechaFin == null) return;
    final format = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es');

    final datos = CertificadoData(
      employee: widget.employee,
      fechaInicio: format.format(_fechaIngreso!),
      fechaFin: format.format(_fechaFin!),
      cargoNombre: _cargoNombre,
      cargoDescripcion: _cargoDescripcion,
      tipoContrato: _tipoContrato,
    );

    final pdfBytes = await CertificatePdfService.generateCertificadosPdf([datos]);
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: 'Certificado_${widget.employee.ci}.pdf');
  }

  Future<void> _iniciarNuevoContrato() async {
    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Iniciar Nuevo Contrato?"),
        content: const Text("El estado cambiará a 'PERSONAL REGISTRADO'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Renovar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmar) return;

    setState(() => _isProcessing = true);
    final provider = context.read<EmployeeProvider>();
    bool success = await provider.reiniciarEstadoRegistrado(widget.employee.id);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Persona lista para nuevo contrato"), backgroundColor: Colors.green));
      }
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: AppColors.primaryYellow, size: 28),
                    const SizedBox(width: 15),
                    Expanded(child: Text("Gestión de Certificado\n${widget.employee.nombre}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: _isLoadingHistory
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _BotonFecha(
                                  titulo: "Fecha de Ingreso",
                                  fecha: _fechaIngreso != null ? format.format(_fechaIngreso!) : "Seleccionar",
                                  onTap: () => _seleccionarFecha(context, true),
                                  bloqueado: _estaTerminado,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _BotonFecha(
                                  titulo: "Fecha de Conclusión",
                                  fecha: _fechaFin != null ? format.format(_fechaFin!) : "Seleccionar",
                                  onTap: () => _seleccionarFecha(context, false),
                                  bloqueado: _estaTerminado,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          if (_estaDevuelto)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                                onPressed: _isProcessing ? null : _guardarYFinalizar,
                                icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.check_circle_outline),
                                label: Text(_isProcessing ? "Guardando..." : "Guardar Fechas y Cerrar Contrato", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          if (_estaTerminado) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow, foregroundColor: AppColors.textDark, padding: const EdgeInsets.symmetric(vertical: 15)),
                                onPressed: _fechaIngreso == null ? null : _imprimirCertificado,
                                icon: const Icon(Icons.print),
                                label: const Text("1. Imprimir Certificado PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue.shade800, padding: const EdgeInsets.symmetric(vertical: 15), elevation: 0),
                                onPressed: _isProcessing ? null : _iniciarNuevoContrato,
                                icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.autorenew),
                                label: const Text("2. Iniciar Nuevo Contrato", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
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

class _BotonFecha extends StatelessWidget {
  final String titulo;
  final String fecha;
  final VoidCallback? onTap;
  final bool bloqueado;

  const _BotonFecha({required this.titulo, required this.fecha, this.onTap, this.bloqueado = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            decoration: BoxDecoration(color: bloqueado ? Colors.grey.shade100 : Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fecha, style: TextStyle(color: bloqueado ? Colors.grey : Colors.black87)),
                Icon(Icons.calendar_today, size: 18, color: bloqueado ? Colors.grey : AppColors.primaryDark),
              ],
            ),
          ),
        ),
      ],
    );
  }
}