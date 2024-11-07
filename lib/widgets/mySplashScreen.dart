import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MySplash extends StatefulWidget {
  final Widget nextScreen; // Pantalla siguiente
  final String lottieAnimation; // Ruta de la animación Lottie

  const MySplash({
    super.key,
    required this.nextScreen,
    required this.lottieAnimation,
  });

  @override
  State<MySplash> createState() => _MySplashState();
}

class _MySplashState extends State<MySplash> {
  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen(
      useImmersiveMode: false,
      duration: const Duration(milliseconds: 4000),
      nextScreen: widget.nextScreen, // Utilizar el parámetro `nextScreen`
      backgroundColor: Colors.white,
      splashScreenBody: Center(
        child: Lottie.asset(
          widget.lottieAnimation, // Utilizar el parámetro `lottieAnimation`
          repeat: true,
        ),
      ),
    );
  }
}
