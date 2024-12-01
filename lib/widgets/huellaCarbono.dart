import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Iconos de FontAwesome
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
  bool _isChartVisible = false;

  @override
  void initState() {
    super.initState();
    _informeFuture = Funciones.generarInformeHuellaCarbono(widget.resumen);
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
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.house, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.infoCircle), // Icono de ayuda
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
            final informe = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Animación Lottie
                    buildLottieAnimation(
                      path: 'assets/animations/factory.json',
                      width: 200,
                      height: 200,
                      repetir: true,
                    ),
                    const SizedBox(height: 20),
                    // Descripción de la huella de carbono
                    _buildResumenTarjeta(
                      '¿Qué es la Huella de Carbono?',
                      'La huella de carbono es una medida que refleja la cantidad de gases de efecto invernadero, especialmente dióxido de carbono (CO2), que se generan directa o indirectamente por nuestras actividades diarias. '
                          'Reciclar ayuda a reducir esta huella al evitar la producción desde cero de materiales y disminuir los desechos en vertederos.',
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
                    _buildResumenTarjeta('Detalles del Informe', informe),
                    const SizedBox(height: 10),
                    _buildResumenTarjeta(
                      'Gráfico de Resumen',
                      'A continuación, se presenta un resumen gráfico de tus materiales reciclados.',
                    ),
                    const SizedBox(height: 10),
                    // Gráfico de Resumen
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
                    // Botón de Exportar PDF
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

  /// Muestra el modal de ayuda con la explicación sobre los cálculos
  void _mostrarModalDeAyuda(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Cómo se calculan los porcentajes?'),
          content: const Text(
            'Los porcentajes de ahorro de carbono se calculan utilizando datos estimados sobre la fabricación y reciclaje de materiales. '
            'Estos modelos consideran factores como el impacto ambiental de la producción, la eficiencia del reciclaje y las emisiones evitadas al reciclar en lugar de desechar. '
            'Recuerda que los cálculos son estimaciones y pueden variar según tu región y prácticas de reciclaje locales.',
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

  /// Construye una tarjeta de resumen
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
