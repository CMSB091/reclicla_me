import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/widgets/noticias.dart';

class MySplash extends StatefulWidget {
  const MySplash({super.key});

  @override
  State<MySplash> createState() => _MySplashState();
}

class _MySplashState extends State<MySplash> {
  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen(
      useImmersiveMode: false,
      duration: const Duration(milliseconds: 3500),
      nextScreen: const NoticiasChatGPT(),
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
