import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/widgets/noticias.dart';

class MySplash extends StatefulWidget {
  final String detectedObject;

  const MySplash({super.key, required this.detectedObject});

  @override
  State<MySplash> createState() => _MySplashState();
}

class _MySplashState extends State<MySplash> {
  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen(
      useImmersiveMode: false,
      duration: const Duration(milliseconds: 3500),
      nextScreen: NoticiasChatGPT(
        initialPrompt: "Quiero que me recomiendes cómo reciclar este producto escaneado: ${widget.detectedObject}",
      ),
      backgroundColor: Colors.white,
      splashScreenBody: Center(
        child: Lottie.asset(
          "assets/animations/lottie-robot.json",
          repeat: true,
        ),
      ),
    );
  }
}
