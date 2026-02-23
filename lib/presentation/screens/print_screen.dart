import 'package:carnetizacion/config/provider/employee_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../config/theme/app_colors.dart';
import '../../config/helpers/pdf_generator_service.dart';
import '../../config/models/employee_model.dart';
import '../widgets/credential_card.dart';

class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key});

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  // Variables independientes para no bloquear ambos botones a la vez
  bool _isGeneratingPdf = false;
  bool _isUpdatingDatabase = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final pendingList = provider.pendingPrintingEmployees;

    // Tomamos máximo 100 credenciales
    final batchToPrint = pendingList.take(100).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // HEADER CON LOS DOS BOTONES
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Impresión de Credenciales",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        pendingList.length > 100
                            ? "Hay ${pendingList.length} pendientes. Mostrando el Lote Actual (100 credenciales)."
                            : "Revisión final de ${pendingList.length} credenciales pendientes.",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // BOTÓN 1: SOLO GENERAR PDF
                // ==========================================
                ElevatedButton.icon(
                  onPressed:
                      (batchToPrint.isEmpty ||
                          _isGeneratingPdf ||
                          _isUpdatingDatabase)
                      ? null
                      : () async {
                          setState(() {
                            _isGeneratingPdf = true;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Generando PDF para revisión... No cierre esta pantalla.",
                              ),
                              backgroundColor: Colors.blue,
                              duration: Duration(seconds: 3),
                            ),
                          );

                          try {
                            // SOLO generamos y mostramos. Cero base de datos.
                            final pdfBytes =
                                await PdfGeneratorService.generateCredentialsPdf(
                                  batchToPrint,
                                );

                            await Printing.layoutPdf(
                              onLayout: (PdfPageFormat format) async =>
                                  pdfBytes,
                              name:
                                  'Credenciales_Lote_${DateTime.now().millisecond}',
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error al generar PDF: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() {
                                _isGeneratingPdf = false;
                              });
                            }
                          }
                        },
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.textDark,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(
                    _isGeneratingPdf
                        ? "Procesando..."
                        : "1. Ver PDF (${batchToPrint.length})",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),

                const SizedBox(width: 15), // Separación entre botones
                // ==========================================
                // BOTÓN 2: CONFIRMAR IMPRESIÓN (BASE DE DATOS)
                // ==========================================
                ElevatedButton.icon(
                  onPressed:
                      (batchToPrint.isEmpty ||
                          _isGeneratingPdf ||
                          _isUpdatingDatabase)
                      ? null
                      : () =>
                            _mostrarDialogoConfirmacion(context, batchToPrint),
                  icon: _isUpdatingDatabase
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    _isUpdatingDatabase ? "Guardando..." : "2. Confirmar Lote",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // GRID DE CREDENCIALES
          Expanded(
            child: batchToPrint.isEmpty
                ? const Center(
                    child: Text("No hay credenciales pendientes de impresión."),
                  )
                : Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 250,
                            crossAxisSpacing: 30,
                            mainAxisSpacing: 30,
                          ),
                      itemCount: batchToPrint.length,
                      itemBuilder: (context, index) {
                        final emp = batchToPrint[index];
                        return Column(
                          children: [
                            Expanded(child: CredentialCard(employee: emp)),
                            const SizedBox(height: 10),
                            Text(
                              emp.nombreCompleto,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIÁLOGO DE SEGURIDAD PARA EL BOTÓN 2
  // ==========================================
  void _mostrarDialogoConfirmacion(BuildContext context, List<Employee> batch) {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar si se hace clic afuera
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text("Confirmar Impresión"),
            ],
          ),
          content: Text(
            "¿Estás seguro de que este lote de ${batch.length} credenciales se imprimió correctamente en papel?\n\nAl confirmar, desaparecerán de esta lista y se cargará el siguiente lote.",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(), // Cierra el diálogo sin hacer nada
              child: const Text(
                "Aún no, cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop(); // Cerramos el diálogo

                // Activamos el icono de carga en el botón Verde
                setState(() {
                  _isUpdatingDatabase = true;
                });

                try {
                  final listToUpdate = List<Employee>.from(batch);
                  final readProvider = context.read<EmployeeProvider>();

                  // Actualizamos a todos en la Base de Datos
                  for (final emp in listToUpdate) {
                    await readProvider.markAsPrinted(emp);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "¡Éxito! Base de datos actualizada. Cargando nuevo lote...",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error al actualizar BD: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    setState(() {
                      _isUpdatingDatabase = false;
                    });
                  }
                }
              },
              child: const Text(
                "Sí, confirmar Lote",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
