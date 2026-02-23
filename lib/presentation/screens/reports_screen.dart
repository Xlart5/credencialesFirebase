import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../config/provider/employee_provider.dart';
import '../../config/helpers/pdf_report_service.dart';
import '../../config/theme/app_colors.dart';
import '../widgets/side_menu.dart'; // Ajusta la ruta de tu menú si es necesario

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // 1. Variable para guardar la opción seleccionada
  String? _selectedCircunscripcion;

  // 2. Lista cerrada de opciones exactas que necesita tu base de datos
  final List<String> _circunscripciones = [
    'C-02', 'C-20', 'C-21', 'C-22', 'C-23',
    'C-24', 'C-25', 'C-26', 'C-27', 'C-28'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final listado = provider.reportData;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const SideMenu(),
      appBar: AppBar(
        title: const Text('Generador de Reportes', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ZONA DE BÚSQUEDA CON DROPDOWN (MENÚ DESPLEGABLE)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Seleccione la Circunscripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      value: _selectedCircunscripcion,
                      items: _circunscripciones.map((String cir) {
                        return DropdownMenuItem<String>(
                          value: cir,
                          child: Text(cir),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCircunscripcion = newValue;
                        });
                        // Opcional: Si quieres que busque automáticamente al elegir sin presionar el botón
                        // if (newValue != null) provider.fetchReportePorCircunscripcion(newValue);
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_selectedCircunscripcion != null) {
                        provider.fetchReportePorCircunscripcion(_selectedCircunscripcion!);
                      } else {
                        // Pequeña alerta si intentan buscar sin seleccionar nada
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor, seleccione una circunscripción primero')),
                        );
                      }
                    },
                    icon: const Icon(Icons.search),
                    label: const Text("Buscar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // RESULTADOS Y BOTÓN IMPRIMIR
            if (listado.isNotEmpty && _selectedCircunscripcion != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Resultados: ${provider.reportTotal} personas",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Printing.layoutPdf(
                        onLayout: (format) async => await PdfReportService.generateCircunscripcionReport(
                          _selectedCircunscripcion!, 
                          listado
                        ),
                        name: 'Reporte_$_selectedCircunscripcion.pdf',
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text("Imprimir PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // TABLA VISUAL DE RESULTADOS
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: ListView.separated(
                    itemCount: listado.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final persona = listado[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryDark.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppColors.primaryDark),
                        ),
                        title: Text(persona['nombreCompleto'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("CI: ${persona['carnetIdentidad']} | Tipo: ${persona['tipo']}"),
                        trailing: Text(persona['celular'] ?? ''),
                      );
                    },
                  ),
                ),
              ),
            ] else if (provider.isLoading) ...[
              const Center(child: CircularProgressIndicator())
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text("Selecciona una circunscripción para ver los datos", style: TextStyle(color: Colors.grey, fontSize: 16)),
                )
              )
            ]
          ],
        ),
      ),
    );
  }
}