import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlasticCountSplashScreen extends StatefulWidget {
  const PlasticCountSplashScreen({super.key});

  @override
  _PlasticCountSplashScreenState createState() => _PlasticCountSplashScreenState();
}

class _PlasticCountSplashScreenState extends State<PlasticCountSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _recycledCountAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Configurar el conteo de reciclaje de 0 a 150
    _recycledCountAnimation = IntTween(begin: 0, end: 150).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    // Configurar la animación de escala para comenzar un poco más pequeña que la pantalla completa y hacer zoom
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Iniciar ambas animaciones al cargar la pantalla
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con animación de zoom, comienza un poco más pequeño que el tamaño de pantalla
          Positioned.fill(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/reciclaje_botellas.png', // Cambia esta ruta según donde guardaste el GIF
                  fit: BoxFit.cover, // Asegura que cubra toda la pantalla
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
                  'Elementos de plástico reciclados',
                  style: GoogleFonts.comicNeue(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${_recycledCountAnimation.value}',
                  style: GoogleFonts.comicNeue(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
