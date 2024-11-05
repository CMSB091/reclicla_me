import 'package:flutter/material.dart';

class PlasticCountSplashScreen extends StatefulWidget {
  const PlasticCountSplashScreen({super.key});

  @override
  _PlasticCountSplashScreenState createState() => _PlasticCountSplashScreenState();
}

class _PlasticCountSplashScreenState extends State<PlasticCountSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _recycledCountAnimation;

  @override
  void initState() {
    super.initState();
    // Configurar el AnimationController para controlar la duración de la animación
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Definir el Tween que va de 0 a 150 y conectarlo al controlador
    _recycledCountAnimation = IntTween(begin: 0, end: 150).animate(_controller)
      ..addListener(() {
        setState(() {}); // Actualiza el estado en cada cambio de valor
      });

    // Iniciar la animación cuando se carga la pantalla
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
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Texto principal de la pantalla de inicio
            const Text(
              'Elementos de plástico reciclados',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // Animación de conteo
            Text(
              '${_recycledCountAnimation.value}', // Mostrar el valor actual del contador
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
