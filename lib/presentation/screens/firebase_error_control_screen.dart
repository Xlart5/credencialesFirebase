import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html; // 🔥 Para descarga en Web
import '../../config/theme/app_colors.dart';

class FirebaseDateEditorScreen extends StatefulWidget {
  const FirebaseDateEditorScreen({super.key});

  @override
  State<FirebaseDateEditorScreen> createState() => _FirebaseDateEditorScreenState();
}

class _FirebaseDateEditorScreenState extends State<FirebaseDateEditorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Variables para la actualización Masiva
  String? _selectedUnit;
  String? _selectedCargo;
  DateTime? _massStartDate;
  DateTime? _massEndDate;

  // Listas y Mapas para los filtros en cascada
  List<String> _unidadesDisponibles = [];
  Map<String, List<String>> _cargosPorUnidad = {};
  
  List<DocumentSnapshot> _empleados = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _cargarUnidadesYEmpleados();
  }

  // =======================================================
  // 1. CARGA DE DATOS Y ARMADO DE CASCADA
  // =======================================================
  Future<void> _cargarUnidadesYEmpleados() async {
    setState(() => _isLoading = true);
    try {
      final snap = await _firestore.collection('personal_historico').get();
      final docs = snap.docs;

      Map<String, Set<String>> tempCargosMap = {};

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        String unidad = data['ultimaUnidad']?.toString().trim() ?? 'Sin Unidad';
        String cargo = data['ultimoCargo']?.toString().trim() ?? 'Sin Cargo';

        if (!tempCargosMap.containsKey(unidad)) {
          tempCargosMap[unidad] = {};
        }
        tempCargosMap[unidad]!.add(cargo);
      }

      // Ordenamos las listas alfabéticamente
      _cargosPorUnidad = tempCargosMap.map((key, value) {
        final listaOrdenada = value.toList()..sort();
        return MapEntry(key, listaOrdenada);
      });

      final unidadesOrdenadas = tempCargosMap.keys.toList()..sort();

      setState(() {
        _empleados = docs;
        _unidadesDisponibles = unidadesOrdenadas;
      });
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =======================================================
  // 🔥 LÓGICA NUEVA: EXPORTAR A EXCEL
  // =======================================================
  Future<void> _exportarExcel() async {
    setState(() => _isLoading = true);
    
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Reporte_Personal'];
      excel.delete('Sheet1'); 

      // Estilo para cabeceras
      CellStyle headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
        fontColorHex: ExcelColor.fromHexString('#FFFFF'),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      // 1. Definir Cabeceras
      List<String> headers = ["CI", "NOMBRE COMPLETO", "UNIDAD", "CARGO", "IMPRESO"];
      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // 2. Filtrar datos según la selección actual
      List<DocumentSnapshot> dataToExport = _empleados;
      if (_selectedUnit != null) {
        dataToExport = dataToExport.where((doc) => doc['ultimaUnidad'] == _selectedUnit).toList();
      }
      if (_selectedCargo != null) {
        dataToExport = dataToExport.where((doc) => doc['ultimoCargo'] == _selectedCargo).toList();
      }

      if (dataToExport.isEmpty) {
        _showSnack("No hay datos para exportar con esa selección", Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      // 3. Llenar filas
      int row = 1;
      for (var doc in dataToExport) {
        final data = doc.data() as Map<String, dynamic>;
        
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(data['ci'] ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(data['nombreCompleto'] ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(data['ultimaUnidad'] ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(data['ultimoCargo'] ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(data['impreso'] == true ? "SÍ" : "NO");
        
        row++;
      }

      // 4. Descargar archivo (Web)
      var fileBytes = excel.save();
      final content = base64Encode(fileBytes!);
      final anchor = html.AnchorElement(href: "data:application/octet-stream;charset=utf-16le;base64,$content")
        ..setAttribute("download", "Reporte_${_selectedCargo ?? 'General'}.xlsx")
        ..click();

      _showSnack("Excel generado con éxito", Colors.green);
    } catch (e) {
      _showSnack("Error al generar Excel: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =======================================================
  // 🔥 LÓGICA: ACTUALIZACIÓN MASIVA POR CARGO
  // =======================================================
  Future<void> _ejecutarActualizacionMasiva() async {
    if (_selectedUnit == null || _selectedCargo == null || _massStartDate == null || _massEndDate == null) {
      _showSnack("Por favor selecciona Unidad, Cargo y ambas Fechas", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Consultamos la unidad en Firebase
      final query = await _firestore.collection('personal_historico')
          .where('ultimaUnidad', isEqualTo: _selectedUnit)
          .get();

      // Filtramos el cargo en memoria
      final docsFiltrados = query.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['ultimoCargo'] == _selectedCargo;
      }).toList();

      if (docsFiltrados.isEmpty) {
        _showSnack("No hay nadie con el cargo $_selectedCargo en la unidad $_selectedUnit", Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      final batch = _firestore.batch();
      int totalContratos = 0;

      for (var personDoc in docsFiltrados) {
        // Entramos a su subcolección de contratos y modificamos todos sus contratos
        final contratosSnap = await personDoc.reference.collection('contratos_cerrados').get();
        
        for (var contrato in contratosSnap.docs) {
          batch.update(contrato.reference, {
            'fechaInicio': _massStartDate!.toIso8601String(),
            'fechaFin': _massEndDate!.toIso8601String(),
          });
          totalContratos++;
        }
      }

      await batch.commit();
      _showSnack("✅ ¡ÉXITO! Se actualizaron $totalContratos certificados de $_selectedCargo", Colors.green);
      
      // Limpiamos fechas después de actualizar para evitar errores
      _massStartDate = null;
      _massEndDate = null;
      
      _cargarUnidadesYEmpleados();
    } catch (e) {
      _showSnack("Error masivo: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =======================================================
  // 🔥 LÓGICA: ACTUALIZACIÓN INDIVIDUAL
  // =======================================================
  Future<void> _editarIndividual(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? initDate;
    DateTime? endDate;

    // Intentamos cargar las fechas actuales del contrato más reciente si existen
    final sub = await doc.reference.collection('contratos_cerrados').orderBy('fechaRegistro', descending: true).limit(1).get();
    if (sub.docs.isNotEmpty) {
      initDate = DateTime.tryParse(sub.docs.first['fechaInicio'] ?? '');
      endDate = DateTime.tryParse(sub.docs.first['fechaFin'] ?? '');
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Fechas para:\n${data['nombreCompleto']}", style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Inicio: ${initDate != null ? DateFormat('dd/MM/yyyy').format(initDate!) : 'No definida'}"),
                trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: initDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setDialogState(() => initDate = picked);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text("Fin: ${endDate != null ? DateFormat('dd/MM/yyyy').format(endDate!) : 'No definida'}"),
                trailing: const Icon(Icons.calendar_today, color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: endDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setDialogState(() => endDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (initDate == null || endDate == null) return;
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                try {
                  final subSnap = await doc.reference.collection('contratos_cerrados').get();
                  final b = _firestore.batch();
                  for (var c in subSnap.docs) {
                    b.update(c.reference, {
                      'fechaInicio': initDate!.toIso8601String(),
                      'fechaFin': endDate!.toIso8601String(),
                    });
                  }
                  await b.commit();
                  _showSnack("Fechas actualizadas correctamente", Colors.green);
                } catch(e) {
                  _showSnack("Error: $e", Colors.red);
                }
                
                setState(() => _isLoading = false);
              },
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }

  void _showSnack(String m, Color c) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _empleados.where((e) {
      final d = e.data() as Map<String, dynamic>;
      final n = (d['nombreCompleto'] ?? '').toString().toLowerCase();
      final ci = (d['ci'] ?? '').toString();
      return n.contains(_searchQuery.toLowerCase()) || ci.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Editor Maestro de Fechas (Firebase)", style: TextStyle(color: Colors.white)), backgroundColor: AppColors.primaryDark),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
          children: [
            // --- SECCIÓN MASIVA ---
            Card(
              margin: const EdgeInsets.all(15),
              color: Colors.blueGrey.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.blueGrey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ACTUALIZACIÓN MASIVA POR CARGO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                    const SizedBox(height: 15),
                    
                    // FILA 1: DROPDOWNS (UNIDAD Y CARGO)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: "1. Selecciona Unidad", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                            items: _unidadesDisponibles.map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedUnit = val;
                                _selectedCargo = null; // Reiniciamos el cargo si cambia la unidad
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCargo,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: "2. Selecciona Cargo", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                            items: (_selectedUnit == null ? <String>[] : _cargosPorUnidad[_selectedUnit]!)
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: _selectedUnit == null ? null : (val) => setState(() => _selectedCargo = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // FILA 2: FECHAS Y BOTONES (Excel y Actualizar)
                    Row(
                      children: [
                        Expanded(child: _dateBtn("Inicio", _massStartDate, (d) => setState(() => _massStartDate = d), Colors.blue)),
                        const SizedBox(width: 15),
                        Expanded(child: _dateBtn("Fin", _massEndDate, (d) => setState(() => _massEndDate = d), Colors.red)),
                        const SizedBox(width: 15),
                        
                        // 🔥 BOTÓN EXCEL (AÑADIDO)
                        ElevatedButton.icon(
                          onPressed: _exportarExcel,
                          icon: const Icon(Icons.download),
                          label: const Text("REPORTE EXCEL", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo, 
                            foregroundColor: Colors.white, 
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                        ),
                        const SizedBox(width: 10),

                        ElevatedButton.icon(
                          onPressed: _ejecutarActualizacionMasiva,
                          icon: const Icon(Icons.flash_on),
                          label: const Text("APLICAR A ESTE CARGO", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange, 
                            foregroundColor: Colors.white, 
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),

            // --- SECCIÓN INDIVIDUAL ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Buscar persona para edición individual por CI o Nombre", 
                  prefixIcon: const Icon(Icons.search), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: filtrados.length,
                itemBuilder: (context, index) {
                  final d = filtrados[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.primaryDark, child: Icon(Icons.person, color: Colors.white)),
                      title: Text(d['nombreCompleto'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("CI: ${d['ci']} | ${d['ultimoCargo']}\nUnidad: ${d['ultimaUnidad']}"),
                      isThreeLine: true,
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: const Text("Fechas"),
                        onPressed: () => _editarIndividual(filtrados[index])
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
    );
  }

  Widget _dateBtn(String label, DateTime? date, Function(DateTime) onPicked, Color iconColor) {
    return OutlinedButton.icon(
      onPressed: () async {
        final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (p != null) onPicked(p);
      },
      icon: Icon(Icons.calendar_today, color: iconColor, size: 18),
      label: Text(
        date == null ? "Elegir $label" : "$label: ${DateFormat('dd/MM/yyyy').format(date)}",
        style: const TextStyle(color: Colors.black87),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.grey.shade300)
      ),
    );
  }
}