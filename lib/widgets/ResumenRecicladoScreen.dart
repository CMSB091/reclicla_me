import 'dart:async';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'dart:io';
import 'package:recila_me/widgets/inicio.dart';

class ResumenRecicladoScreen extends StatefulWidget {
  const ResumenRecicladoScreen({super.key});

  @override
  _ResumenRecicladoScreenState createState() => _ResumenRecicladoScreenState();
}

class _ResumenRecicladoScreenState extends State<ResumenRecicladoScreen> {
  late Future<Map<String, int>> _resumenFuture = Future.value({});
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
    // Solicitar permisos de almacenamiento
    var status = await Permission.storage.request();

    if (status.isGranted) {
      var excel = Excel.createExcel(); // Crear un archivo Excel
      Sheet sheetObject = excel['Resumen']; // Crear una hoja llamada "Resumen"

      // Agregar encabezados
      sheetObject.appendRow(['Material', 'Cantidad']);

      // Agregar datos
      residuos.forEach((material, cantidad) {
        sheetObject.appendRow([material, cantidad]);
      });

      // Obtener el directorio de descargas
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      String filePath = '${directory.path}/resumen_reciclado.xlsx';

      // Guardar el archivo en la carpeta de descargas
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.save()!);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo exportado a: $filePath')),
      );
    } else {
      // Mostrar mensaje de error si no se otorgan los permisos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de almacenamiento denegado')),
      );
    }
  }

  Future<void> _showConfirmDialog(
      BuildContext context, Map<String, int> residuos) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar acción'),
          content: const Text(
              '¿Estás seguro de que deseas generar el archivo Excel?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                await exportToExcel(residuos); // Genera el archivo Excel
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResiduoInfoModal(
      BuildContext context, String iconPath, String descripcion) async {
    BuildContext? dialogContext; // Contexto del CircularProgressIndicator

    // Mostrar el CircularProgressIndicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context; // Guardar el contexto del indicador
        return const Center(child: CircularProgressIndicator());
      },
    );

    String chatGptResponse;
    try {
      // Generar un prompt para la consulta a ChatGPT
      final String prompt =
          'Proporciona información breve pero útil sobre el material "$descripcion" y una forma efectiva de reciclar. Actua como un experto en reciclaje. Recuerda que debes ser muy breve en la respuesta';
      chatGptResponse = await Funciones.getChatGPTResponse(prompt);
    } catch (e) {
      chatGptResponse = 'Hubo un error al obtener la información: $e';
    }

    // Cerrar el CircularProgressIndicator
    if (dialogContext != null) {
      Navigator.of(dialogContext!).pop(); // Cierra el indicador
    }

    // Mostrar el modal con la información obtenida
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Image.asset(
                iconPath,
                width: 100,
                height: 100,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  descripcion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              chatGptResponse,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el modal actual
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade200,
        title: const Text(
          'Resumen de Reciclados',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 22,
            color: Colors.black,
          ),
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
            icon: const FaIcon(FontAwesomeIcons.circleQuestion),
            onPressed: () {
              Funciones().showGameRules(context,'Ayuda','Presiona los iconos de la tabla para obtener información extra acerca de los tipos de residuos');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Contenido principal que se ajusta dinámicamente
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
                    child: Text('No se encontraron datos.'),
                  );
                }

                final resumen = snapshot.data!;
                final int totalCantidad =
                    resumen.values.fold(0, (sum, item) => sum + item);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Table(
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
                                  color:
                                      resumen.entries.toList().indexOf(entry) %
                                                  2 ==
                                              0
                                          ? Colors.grey.shade100
                                          : Colors.white,
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        _showResiduoInfoModal(
                                          context,
                                          _getMaterialIconPath(entry.key),
                                          entry.key,
                                        );
                                      },
                                      child: Image.asset(
                                        _getMaterialIconPath(entry.key),
                                        width: 40,
                                        height: 40,
                                      ),
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
                                        fontWeight: FontWeight.bold,
                                      ),
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
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () async {
                                if (resumen.isNotEmpty) {
                                  await _showConfirmDialog(context, resumen);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('No hay datos para exportar'),
                                    ),
                                  );
                                }
                              },
                              icon: Image.asset(
                                'assets/icons/excel_icon.png',
                                height: 50,
                                width: 50,
                              ),
                              tooltip: 'Exportar a Excel',
                            ),
                            const Text(
                              'Exportar',
                              style: TextStyle(
                                fontFamily: 'Artwork',
                                fontSize: 25,
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
          // Flecha fija al pie de la pantalla
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomRight,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MyInicio(cameras: []), // Página de destino
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
