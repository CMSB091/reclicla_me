import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/huellaCarbono.dart';
import 'package:recila_me/widgets/inicio.dart';

class ResumenRecicladoScreen extends StatefulWidget {
  const ResumenRecicladoScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ResumenRecicladoScreenState createState() => _ResumenRecicladoScreenState();
}

class _ResumenRecicladoScreenState extends State<ResumenRecicladoScreen> {
  late Future<Map<String, int>> _resumenFuture;
  String _usuarioEmail = "";

  @override
  void initState() {
    super.initState();
    _resumenFuture = _initializeResumen();
  }

  Future<Map<String, int>> _initializeResumen() async {
    try {
      final userEmail = await Funciones().getCurrentUserEmail();
      if (userEmail != null) {
        _usuarioEmail = userEmail;
        return await firestoreService.getResumenReciclado(_usuarioEmail);
      }
    } catch (e) {
      debugPrint('Error al inicializar resumen: $e');
    }
    return {}; // Devuelve un mapa vacío si ocurre un error.
  }

  String generarMensajeComparacion(Map<String, int> totales) {
    final totalMesActual = totales['mesActual'] ?? 0;
    final totalMesPasado = totales['mesPasado'] ?? 0;

    if (totalMesPasado > 0) {
      final incremento =
          ((totalMesActual - totalMesPasado) / totalMesPasado * 100).round();
      return incremento >= 0
          ? '¡Has reciclado un ${incremento.abs()}% más materiales este mes en comparación con el mes pasado!'
          : 'Este mes reciclaste un ${incremento.abs()}% menos materiales que el mes pasado. ¡A seguir mejorando!';
    } else {
      return '¡Es tu primer mes reciclando! ¡Buen trabajo!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade200,
        title: Row(
          children: [
            Lottie.asset(
              'assets/animations/lotti-recycle.json',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'Resumen',
              style: TextStyle(
                fontFamily: 'Artwork',
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Lottie.asset(
              'assets/animations/lotti-trash.json',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.house, color: Colors.black),
          onPressed: () {
            Funciones.navigateToHome(context);
          },
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circleQuestion),
            onPressed: () {
              Funciones().showGameRules(
                context,
                'Ayuda',
                'Presiona los íconos en la lista para obtener más información sobre cada tipo de residuo.\n\n Presiona el icono de xls para obtener el resumen en formato excel',
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _resumenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/recycling3.json',
                  width: 400,
                  height: 400,
                ),
                const SizedBox(height: 20),
                Text(
                  '¡Aún no has reciclado nada!',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Empieza hoy y ayuda a cuidar el planeta 🌍',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyInicio(cameras: []),
                      ),
                    );
                  },
                  icon: const FaIcon(FontAwesomeIcons.recycle),
                  label: const Text('¡Empieza a reciclar ahora!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 20.0),
                    textStyle: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          }

          final resumen = snapshot.data!;
          final total = resumen.values.reduce((a, b) => a + b);
          final mensajeComparacion = generarMensajeComparacion(resumen);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: resumen.entries.map((entry) {
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: Image.asset(
                          Funciones.getMaterialIconPath(entry.key),
                          width: 50,
                          height: 50,
                        ),
                        title: Text(
                          entry.key.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Text(
                          entry.value == 1
                              ? '${entry.value} Unidad'
                              : '${entry.value} Unidades',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => Funciones.showResiduoInfoModal(
                          context,
                          Funciones.getMaterialIconPath(entry.key),
                          entry.key,
                        ),
                      ),
                    );
                  }).toList()
                    ..add(
                      Card(
                        color: Colors.lightGreen.shade100,
                        elevation: 4,
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                'TOTAL RECICLADO',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              trailing: TweenAnimationBuilder<int>(
                                duration: const Duration(seconds: 2),
                                tween: IntTween(begin: 0, end: total),
                                builder: (context, value, child) {
                                  return Text(
                                    '$value',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                mensajeComparacion,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () async {
                      if (resumen.isNotEmpty) {
                        final tienePermiso =
                            await Funciones().verificarPermisosAlmacenamiento();
                        if (tienePermiso) {
                          try {
                            await Funciones.exportToExcel(
                              resumen,
                              (filePath) {
                                Funciones.showSnackBar(
                                  context,
                                  'El archivo se guardó correctamente en $filePath',
                                );
                              },
                            );
                          } catch (e) {
                            Funciones.showSnackBar(
                              context,
                              'Error al exportar el archivo: $e',
                            );
                          }
                        } else {
                          Funciones.showSnackBar(
                            context,
                            'Permiso de almacenamiento denegado. No se puede exportar el archivo.',
                          );
                        }
                      } else {
                        Funciones.showSnackBar(
                          context,
                          'No hay datos para exportar.',
                        );
                      }
                    },
                    icon: Image.asset(
                      'assets/icons/excel_icon.png',
                      height: 50,
                      width: 50,
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowRight,
                      size: 50,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HuellaCarbonoScreen(resumen: snapshot.data!),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
