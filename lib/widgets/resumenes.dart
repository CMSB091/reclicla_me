import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlasticCountSplashScreen extends StatefulWidget {
  final int recycledItemCount;

  const PlasticCountSplashScreen({super.key, this.recycledItemCount = 150});

  @override
  _PlasticCountSplashScreenState createState() =>
      _PlasticCountSplashScreenState();
}

class _PlasticCountSplashScreenState extends State<PlasticCountSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late AnimationController _backgroundController;
  late Animation<int> _recycledCountAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador para el conteo de reciclaje
    _countController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Configurar el conteo de reciclaje de 0 al valor especificado
    _recycledCountAnimation = IntTween(begin: 0, end: widget.recycledItemCount)
        .animate(_countController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        // Detener la animación cuando alcanza el estado completo
        if (status == AnimationStatus.completed) {
          _countController.stop();
        }
      });

    // Iniciar la animación del contador (una sola vez)
    _countController.forward();

    // Controlador para la animación de fondo
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Configurar la animación de escala para la imagen de fondo (sin bucle)
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Iniciar la animación de fondo una sola vez
    _backgroundController.forward();
  }

  @override
  void dispose() {
    _countController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con animación de zoom, filtro de color y desenfoque
          Positioned.fill(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Aplicar desenfoque
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                      Colors.green.withOpacity(0.3), BlendMode.overlay),
                  child: Image.asset(
                    'assets/images/reciclaje_botellas.png',
                    fit: BoxFit.cover, // Asegura que la imagen cubra toda la pantalla
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ),
          // Texto superpuesto
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Objetos de plástico reciclados',
                  style: GoogleFonts.comicNeue(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 6.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${_recycledCountAnimation.value}',
                  style: GoogleFonts.comicNeue(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 6.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
