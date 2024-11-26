import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/ResumenGrafico.dart';
import 'package:recila_me/widgets/lottieWidget.dart';
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

  @override
  void initState() {
    super.initState();
    _informeFuture = _generarInformeHuellaCarbono(widget.resumen);
    _descripcionHuellaFuture = _obtenerDescripcionHuella();
  }

  Future<String> _generarInformeHuellaCarbono(Map<String, int> resumen) async {
    const pesosPorUnidad = {
      'Papel': 0.05,
      'Plástico': 0.1,
      'Vidrio': 0.5,
      'Metal': 0.2,
    };

    const conversionCarbono = {
      'Papel': 0.9,
      'Plástico': 1.5,
      'Vidrio': 0.5,
      'Metal': 2.0,
    };

    final detallesMateriales = resumen.entries.map((entry) {
      final material = entry.key;
      final cantidad = entry.value;
      final pesoPorUnidad = pesosPorUnidad[material] ?? 0.0;
      final pesoTotal = cantidad * pesoPorUnidad;
      final carbonoAhorrado = pesoTotal * (conversionCarbono[material] ?? 0.0);
      return '$material: $cantidad unidades, ${pesoTotal.toStringAsFixed(2)} kg reciclados, '
          '${carbonoAhorrado.toStringAsFixed(2)} kg de carbono ahorrados.';
    }).join('\n');

    final totalCarbonoAhorrado = resumen.entries.fold(0.0, (sum, entry) {
      final material = entry.key;
      final cantidad = entry.value;
      final pesoPorUnidad = pesosPorUnidad[material] ?? 0.0;
      final pesoTotal = cantidad * pesoPorUnidad;
      final carbonoAhorrado = pesoTotal * (conversionCarbono[material] ?? 0.0);
      return sum + carbonoAhorrado;
    });

    final porcentajeReduccion = (totalCarbonoAhorrado / 10000) * 100;

    final informe = '''
  Detalles del Ahorro por Material:
  $detallesMateriales

  Total de Carbono Ahorrado: ${totalCarbonoAhorrado.toStringAsFixed(2)} kg
  Porcentaje de Reducción de Huella de Carbono: ${porcentajeReduccion.toStringAsFixed(2)}%
  ''';

    return informe;
  }

  Future<String> _obtenerDescripcionHuella() async {
    const prompt = '''
      Explica brevemente qué es la huella de carbono de manera clara y comprensible para el usuario final.
    ''';

    try {
      final respuestaIA = await Funciones.getChatGPTResponse(prompt);
      return respuestaIA;
    } catch (e) {
      return 'Hubo un error al obtener la descripción de la huella de carbono: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Huella de Carbono',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green.shade200,
      ),
      body: FutureBuilder<String>(
        future: Future.wait([_informeFuture, _descripcionHuellaFuture])
            .then((results) => results.join('|||')), // Combina ambas respuestas
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
            final respuestas = snapshot.data!.split('|||');
            final informe = respuestas[0];
            final descripcionHuella = respuestas[1];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado con animación
                    buildLottieAnimation(path: 'assets/animations/factory.json',width: 200, height: 200, repetir: true),
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
                    // Tarjeta de descripción de la huella de carbono
                    _buildResumenTarjeta(
                      '¿Qué es la Huella de Carbono?',
                      descripcionHuella,
                    ),
                    const SizedBox(height: 10),
                    // Tarjetas con el informe
                    _buildResumenTarjeta(
                      'Detalles del Informe',
                      informe,
                    ),
                    const SizedBox(height: 10),
                    _buildResumenTarjeta(
                      'Gráfico de Resumen',
                      'A continuación, se presenta un resumen gráfico de tus materiales reciclados.',
                    ),
                    const SizedBox(height: 10),
                    // Gráfico
                    VisibilityDetector(
                      key: const Key('pie_chart_visibility'),
                      onVisibilityChanged: (info) {
                        if (info.visibleFraction > 0.5 && !_isChartVisible) {
                          setState(() {
                            _isChartVisible = true;
                          });
                        }
                      },
                      child: SizedBox(
                        height: 400,
                        child: ResumenGrafico(
                          resumen: widget.resumen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Botón de exportación
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await Funciones.exportToPDFWithChart(
                            informe,
                            widget.resumen,
                            (filePath) {
                              Funciones.showSnackBar(
                                context,
                                'Informe exportado como PDF en $filePath',
                              );
                            },
                          );
                        } catch (e) {
                          Funciones.showSnackBar(
                            context,
                            'Error al exportar el PDF con gráfico: $e',
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar PDF con Gráfico'),
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

  Widget _buildResumenTarjeta(String titulo, String contenido) {
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
            Text(
              contenido,
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
