import 'dart:async';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/mensajeInicio.dart';

class ReciclaMeApp extends StatelessWidget {
  final List<CameraDescription>? cameras;

  const ReciclaMeApp({super.key, this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReciclaMe',
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        primarySwatch: Colors.green,
      ),
      home: SplashScreen(cameras: cameras),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;

  const SplashScreen({super.key, this.cameras});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0;
  late BuildContext _context;
  String _tipMessage = "";

  @override
  void initState() {
    super.initState();
    _context = context;
    _fetchTipAndStartLoading();
  }

  Future<void> _fetchTipAndStartLoading() async {
    try {
      // Fecha límite para tips recientes
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      // Eliminar tips más antiguos (vaciado semanal)
      final oldTipsQuery = await FirebaseFirestore.instance
          .collection('tips')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (var doc in oldTipsQuery.docs) {
        await doc.reference.delete();
      }

      // Obtener tips recientes
      final tipsQuery = await FirebaseFirestore.instance
          .collection('tips')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .get();

      final recentTips =
          tipsQuery.docs.map((doc) => doc['message'] as String).toList();

      // Generar un nuevo tip con mayor variedad
      final topics = [
        "reciclaje de plástico",
        "reciclaje de papel",
        "compostaje doméstico",
        "reutilización creativa",
        "cuidado del agua",
        "reciclaje electrónico",
        "reciclaje de vidrio",
        "reducción de residuos en la cocina",
        "reciclaje de textiles",
        "reciclaje de metales",
        "ahorro energético en el hogar",
        "cómo reducir el uso de plásticos de un solo uso",
        "beneficios del compostaje en jardines",
        "reciclaje de baterías y pilas",
        "reciclaje de electrodomésticos viejos",
        "cuidado de áreas verdes",
        "reciclaje de cartón",
        "minimización de desperdicios en eventos",
        "formas de reutilizar botellas de vidrio",
        "reciclaje de residuos orgánicos",
        "cómo separar adecuadamente la basura",
        "impacto del reciclaje en el cambio climático",
        "reciclaje de envases de aluminio",
        "cómo hacer tu propio compost",
        "reutilización de frascos y tarros",
        "formas creativas de dar nueva vida a ropa vieja",
        "beneficios de reparar antes de desechar",
        "importancia de reciclar juguetes viejos",
        "cómo participar en programas de reciclaje locales",
        "reciclaje en la oficina",
        "formas de reducir el desperdicio de alimentos",
        "reciclaje de CDs y DVDs",
        "cómo reciclar correctamente el aceite de cocina usado",
        "importancia del reciclaje en las escuelas",
        "ideas para reutilizar cajas de cartón",
        "reciclaje de materiales de construcción",
        "cómo reducir la contaminación digital (e-waste)",
        "cómo hacer muebles con materiales reciclados",
        "formas de reciclar o donar libros viejos",
        "reciclaje de escombros y materiales de demolición"
      ];

      final randomTopic = (topics..shuffle()).first;

      String newTip = await Funciones.getChatGPTResponse(
          "Proporciona un consejo corto y útil sobre $randomTopic. Responde únicamente con el consejo, sin introducción ni explicaciones adicionales.");

      // Verificar si el tip ya existe
      if (recentTips.contains(newTip)) {
        // Seleccionar un tip al azar si el nuevo ya existe
        final allTipsQuery =
            await FirebaseFirestore.instance.collection('tips').get();

        if (allTipsQuery.docs.isNotEmpty) {
          final randomTip = (allTipsQuery.docs..shuffle()).first['message'];
          _tipMessage = randomTip;
        } else {
          _tipMessage =
              "Antes de desechar un artículo, considera si se puede reciclar o reutilizar de alguna manera.";
        }
      } else {
        // Guardar el nuevo tip si no existe
        await FirebaseFirestore.instance.collection('tips').add({
          'message': newTip,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _tipMessage = newTip;
      }
    } catch (e) {
      // Manejo de errores con mensaje predeterminado
      _tipMessage =
          "Antes de desechar un artículo, considera si se puede reciclar o reutilizar de alguna manera.";
    } finally {
      _startLoading();
    }
  }

  void _startLoading() {
    Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {
      setState(() {
        if (_progress >= 1) {
          timer.cancel();
          // Navega a la siguiente pantalla cuando la carga está completa
          Navigator.of(_context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => mensajeInicio(widget.cameras,
                  tipMessage: _tipMessage), // Pasa el mensaje como parámetro
            ),
          );
        } else {
          _progress += 0.02;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFccffcc), // Fondo verde muy claro
      body: Center(
        child: SizedBox(
          width: screenWidth * 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/reciclaje1.gif',
                width: screenWidth * 0.5,
                height: screenHeight * 0.3,
              ),
              const SizedBox(height: 20),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'ReciclaMe',
                  style: TextStyle(
                    fontFamily: 'Artwork',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_progress > 0)
                Container(
                  width: screenWidth * 0.6,
                  height: 20, // Altura de la barra de progreso
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors
                        .grey[300], // Color de fondo de la barra de progreso
                  ),
                  child: Stack(
                    children: [
                      // Fondo de la barra de progreso
                      Container(
                        width: _progress *
                            (screenWidth *
                                0.6), // Ancho de llenado de la barra de progreso
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors
                              .green, // Color de llenado de la barra de progreso
                        ),
                      ),
                      // Porcentaje de carga
                      Center(
                        child: Text(
                          '${(_progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
