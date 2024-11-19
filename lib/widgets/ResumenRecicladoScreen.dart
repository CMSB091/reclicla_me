import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ResumenRecicladoScreen extends StatefulWidget {
  const ResumenRecicladoScreen({super.key});

  @override
  _ResumenRecicladoScreenState createState() => _ResumenRecicladoScreenState();
}

class _ResumenRecicladoScreenState extends State<ResumenRecicladoScreen> {
  late Future<Map<String, int>> _resumenFuture;
  String _usuarioEmail = "";

  @override
  void initState() {
    super.initState();
    _initializeResumen();
  }

  Future<void> _initializeResumen() async {
    String? userEmail = await Funciones().getCurrentUserEmail();

    if (userEmail != null) {
      setState(() {
        _usuarioEmail = userEmail;
        _resumenFuture = FirestoreService().getResumenReciclado(_usuarioEmail);
      });
    } else {
      setState(() {
        _resumenFuture = Future.value({});
      });
    }
  }

  String _getMaterialIconPath(String material) {
    switch (material.toLowerCase()) {
      case 'plastico':
        return 'assets/icons/plastico.png';
      case 'vidrio':
        return 'assets/icons/vidrio.png';
      case 'papel':
        return 'assets/icons/papel.png';
      case 'metal':
        return 'assets/icons/metal.png';
      case 'aluminio':
        return 'assets/icons/aluminio.png';
      case 'carton':
        return 'assets/icons/carton.png';
      case 'isopor':
        return 'assets/icons/isopor.png';
      default:
        return 'assets/icons/residuos.png';
    }
  }

  Future<void> exportToExcel(Map<String, int> residuos) async {
    var excel = Excel.createExcel(); // Crear un archivo Excel
    Sheet sheetObject = excel['Resumen']; // Crear una hoja llamada "Resumen"

    // Agregar encabezados
    sheetObject.appendRow(['Material', 'Cantidad']);

    // Agregar datos
    residuos.forEach((material, cantidad) {
      sheetObject.appendRow([material, cantidad]);
    });

    // Obtener el directorio donde guardar el archivo
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/resumen_reciclado.xlsx';

    // Guardar el archivo
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.save()!);

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Archivo exportado a: $filePath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade200,
        title: const Column(
          children: [
            Text('Resumen de Reciclados',
                style: TextStyle(
                    fontFamily: 'Artwork', fontSize: 25, color: Colors.black)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.house, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black),
            onPressed: () async {
              final resumen = await _resumenFuture;
              if (resumen.isNotEmpty) {
                await exportToExcel(resumen);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay datos para exportar')),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FutureBuilder<Map<String, int>>(
                  future: _resumenFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No se encontraron datos.'));
                    }

                    final resumen = snapshot.data!;
                    final int totalCantidad = resumen.values.fold(
                        0, (sum, item) => sum + item);

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Table(
                          border: TableBorder.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1), // Columna de íconos
                            1: FlexColumnWidth(2), // Columna de materiales
                            2: FlexColumnWidth(1), // Columna de cantidades
                          },
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                              ),
                              children: [
                                SizedBox.shrink(),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 8.0),
                                  child: Text(
                                    'Material',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 8.0),
                                  child: Text(
                                    'Cantidad(Un.)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            ...resumen.entries.map((entry) {
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: resumen.entries
                                              .toList()
                                              .indexOf(entry) %
                                          2 ==
                                      0
                                      ? Colors.grey.shade100
                                      : Colors.white,
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      _getMaterialIconPath(entry.key),
                                      width: 40,
                                      height: 40,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 8.0),
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 8.0),
                                    child: Text(
                                      entry.value.toString(),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            }),
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.lightGreen.shade200,
                              ),
                              children: [
                                const SizedBox.shrink(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 8.0),
                                  child: Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 8.0),
                                  child: Text(
                                    totalCantidad.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.arrowRight,
                  size: 50,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ResumenRecicladoScreen(), // Cambiar destino
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
