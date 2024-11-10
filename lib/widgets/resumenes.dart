import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class ReusableCountSplashScreen extends StatefulWidget {
  final int itemCount;
  final String title;
  final String backgroundImagePath;

  const ReusableCountSplashScreen({
    Key? key,
    required this.itemCount,
    required this.title,
    required this.backgroundImagePath,
  }) : super(key: key);

  @override
  _ReusableCountSplashScreenState createState() =>
      _ReusableCountSplashScreenState();
}

class _ReusableCountSplashScreenState extends State<ReusableCountSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late AnimationController _backgroundController;
  late Animation<int> _countAnimation;
  late Animation<double> _scaleAnimation;
  bool _showLottieAnimation = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Controlador para el conteo
    _countController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Configurar el conteo de 0 al valor especificado
    _countAnimation = IntTween(begin: 0, end: widget.itemCount).animate(_countController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _showLottieAnimation = true; // Mostrar animación de Lottie cuando termine el conteo
          });
          _playCompletionSound(); // Reproducir sonido al finalizar el conteo
          _vibrateOnCompletion(); // Vibrar al finalizar el conteo
          _countController.stop();
        }
      });

    _countController.forward();

    // Controlador para la animación de fondo
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Configurar la animación de escala para la imagen de fondo
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _backgroundController.forward();
  }

  // Función para reproducir el sonido
  Future<void> _playCompletionSound() async {
    await _audioPlayer.play(AssetSource('audio/congrats.mp3'));
  }

  // Función para activar la vibración
  Future<void> _vibrateOnCompletion() async {
    if (await Vibrate.canVibrate) {
      Vibrate.vibrate(); // Vibración simple
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _backgroundController.dispose();
    _audioPlayer.dispose(); // Liberar el reproductor de audio al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con animación de zoom y desenfoque
          Positioned.fill(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.backgroundImagePath,
                    fit: BoxFit.cover,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                    child: Container(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Texto superpuesto
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
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
                  '${_countAnimation.value}',
                  style: GoogleFonts.comicNeue(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.7),
                        offset: const Offset(3.0, 3.0),
                      ),
                      Shadow(
                        blurRadius: 20.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(5.0, 5.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Animación Lottie en pantalla completa, sobre los demás elementos, repitiéndose y escalada
          if (_showLottieAnimation)
            Positioned.fill(
              child: Center(
                child: Transform.scale(
                  scale: 1.5,
                  child: Lottie.asset(
                    'assets/animations/fireworks.json',
                    repeat: true,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
