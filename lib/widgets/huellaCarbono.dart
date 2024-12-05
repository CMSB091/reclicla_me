import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/ResumenGrafico.dart';
import 'package:recila_me/widgets/lottieWidget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HuellaCarbonoScreen extends StatefulWidget {
  final Map<String, int> resumen;

  const HuellaCarbonoScreen({Key? key, required this.resumen})
      : super(key: key);

  @override
  _HuellaCarbonoScreenState createState() => _HuellaCarbonoScreenState();
}

class _HuellaCarbonoScreenState extends State<HuellaCarbonoScreen> {
  late Future<String> _informeFuture;
  late Future<String> _descripcionHuellaFuture;
  bool _isChartVisible = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _informeFuture = Funciones.generarInformeHuellaCarbono(widget.resumen);
    _descripcionHuellaFuture = _loadDescripcionHuella();
  }

  Future<String> _loadDescripcionHuella() async {
    return await Funciones.getChatGPTResponse(
        "Explica brevemente qué es la huella de carbono y cómo reciclar puede ayudar a reducirla.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Huella de Carbono',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green.shade200,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.house, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.infoCircle),
            onPressed: () {
              _mostrarModalDeAyuda(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _informeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            );
          } else {
            final double reduccionTotal =
                _calcularReduccionTotal(widget.resumen);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildLottieAnimation(
                      path: 'assets/animations/factory.json',
                      width: 200,
                      height: 200,
                      repetir: true,
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<String>(
                      future: _descripcionHuellaFuture,
                      builder: (context, descSnapshot) {
                        if (descSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (descSnapshot.hasError) {
                          return _buildResumenTarjeta(
                            '¿Qué es la Huella de Carbono?',
                            const Text(
                              'Error al cargar la descripción.',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        } else {
                          return _buildResumenTarjeta(
                            '¿Qué es la Huella de Carbono?',
                            Text(
                              descSnapshot.data ??
                                  'No se pudo obtener la información.',
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Impacto de tu Reciclaje',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildResumenTarjeta(
                      'Detalles del Informe',
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'Con tu reciclaje has reducido un estimado de ',
                            ),
                            TextSpan(
                              text: '${reduccionTotal.toStringAsFixed(2)}%',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const TextSpan(
                              text: ' de tu huella de carbono en el año.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    VisibilityDetector(
                      key: const Key('pie_chart_visibility'),
                      onVisibilityChanged: (info) {
                        if (info.visibleFraction > 0.5 && !_isChartVisible) {
                          setState(() {
                            _isChartVisible = true;
                          });
                        }
                      },
                      child: Screenshot(
                        controller: _screenshotController,
                        child: SizedBox(
                          height: 400,
                          child: ResumenGrafico(
                            resumen: widget.resumen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final conceptoHuella = await _descripcionHuellaFuture;
                          final imageBytes =
                              await _screenshotController.capture();

                          if (imageBytes == null) {
                            Funciones.showSnackBar(
                              context,
                              'No se pudo capturar el gráfico.',
                              color: Colors.red,
                            );
                            return;
                          }

                          await Funciones.exportToPDFWithChart(
                            conceptoHuella,
                            'Con tu reciclaje has reducido un estimado de ${reduccionTotal.toStringAsFixed(2)}% de tu huella de carbono en el año',
                            widget.resumen,
                            imageBytes,
                            (filePath) {
                              Funciones.showSnackBar(
                                context,
                                'PDF generado en: $filePath',
                              );
                            },
                          );
                        } catch (e) {
                          Funciones.showSnackBar(
                            context,
                            'Error al exportar el PDF con gráfico: $e',
                            color: Colors.red,
                          );
                        }
                      },
                      icon: const Icon(FontAwesomeIcons.filePdf),
                      label: const Text('Exportar informe en formato PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _mostrarModalDeAyuda(BuildContext context) {
    final Future<String> _ayudaFuture = Funciones.getChatGPTResponse(
        "Explica de manera breve y clara cómo se calculan los porcentajes de ahorro de carbono en función del reciclaje de materiales.");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Cómo se calculan los porcentajes?'),
          content: FutureBuilder<String>(
            future: _ayudaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return const SingleChildScrollView(
                  child: Text(
                    'Error al cargar la información. Por favor, inténtalo de nuevo más tarde.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              } else {
                return SingleChildScrollView(
                  child: Text(
                    snapshot.data ?? 'No se pudo obtener la información.',
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumenTarjeta(String titulo, Widget contenido) {
    return Card(
      color: Colors.lightGreen.shade100,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            contenido,
          ],
        ),
      ),
    );
  }

  double _calcularReduccionTotal(Map<String, int> resumen) {
    double total = 0;
    resumen.forEach((material, cantidad) {
      double reduccionPorUnidad = _obtenerReduccionPorMaterial(material);
      total += cantidad * reduccionPorUnidad;
    });
    return total;
  }

  double _obtenerReduccionPorMaterial(String material) {
    const reducciones = {
      'Plástico': 0.5,
      'Vidrio': 0.8,
      'Papel': 0.3,
      'Metal': 1.0,
    };
    return reducciones[material] ?? 0.0;
  }
}
