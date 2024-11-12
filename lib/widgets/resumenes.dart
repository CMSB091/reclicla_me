import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:recila_me/widgets/inicio.dart';

class ReusableCountSplashScreen extends StatefulWidget {
  final String title;
  final int itemCount;
  final String backgroundImagePath;
  final int currentPage; // Número de página actual
  final bool isFirstPage; // Indica si es la primera página

  const ReusableCountSplashScreen({
    super.key,
    required this.title,
    required this.itemCount,
    required this.backgroundImagePath,
    this.currentPage = 1, // Por defecto la primera página
    this.isFirstPage = false,
  });

  @override
  _ReusableCountSplashScreenState createState() =>
      _ReusableCountSplashScreenState();
}

class _ReusableCountSplashScreenState extends State<ReusableCountSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late AnimationController _titleController;
  late AnimationController _arrowController;
  late Animation<int> _countAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<double> _arrowOpacityAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showLottieAnimation = false;
  bool _showArrowIcon = false;

  @override
  void initState() {
    super.initState();

    _initializeAnimations();

    // Inicializamos _countAnimation con el valor de itemCount
    _countAnimation =
        IntTween(begin: 0, end: widget.itemCount).animate(_countController);

    _startTitleAnimation();
  }

  void _initializeAnimations() {
    _titleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _titleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

    _countController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _arrowController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _arrowOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeIn),
    );
  }

  void _startTitleAnimation() {
    _titleController.forward().whenComplete(() {
      _startCountAnimation();
    });
  }

  void _startCountAnimation() {
    _countController.reset();
    _countAnimation =
        IntTween(begin: 0, end: widget.itemCount).animate(_countController)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _playCompletionSound();
              _vibrateOnCompletion();
              _showFireworks(); // Iniciar animación de fuegos artificiales
            }
          });

    _countController.forward();
  }

  void _showFireworks() {
    setState(() {
      _showLottieAnimation = true;
    });

    // Detener la animación de fuegos artificiales después de 3 segundos y mostrar las flechas
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _showLottieAnimation = false;
        _showArrowIcon = true;
      });
      _arrowController
          .forward(); // Inicia la animación de opacidad de las flechas
    });
  }

  Future<void> _playCompletionSound() async {
    await _audioPlayer.play(AssetSource('audio/congrats.mp3'));
  }

  Future<void> _vibrateOnCompletion() async {
    if (await Vibrate.canVibrate) {
      Vibrate.vibrate();
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _titleController.dispose();
    _arrowController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onArrowRightPressed(int nextPage) {
    late String cadena;
    late int contador;
    late String background;

    if (nextPage == 2) {
      cadena = 'Objetos de Metal Reciclados';
      contador = 200;
      background = 'assets/images/reciclaje_metal.png';
    } else if (nextPage == 3) {
      cadena = 'Objetos de Vidrio Reciclados';
      contador = 300;
      background = 'assets/images/reciclaje_botellas.png';
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReusableCountSplashScreen(
          title: cadena,
          itemCount: contador,
          backgroundImagePath: background,
          currentPage: nextPage,
          isFirstPage: nextPage == 1,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Transición deslizante desde la derecha
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  // Acción para la flecha izquierda (página anterior o menú de inicio)
  void _onArrowLeftPressed(int previousPage) {
    if (widget.currentPage == 1) {
      Navigator.of(context).pushReplacementNamed(
          '/home'); // Navegar al menú de inicio si es la primera página
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ReusableCountSplashScreen(
            title: 'Objetos de Plástico Reciclados',
            itemCount: 150,
            backgroundImagePath: 'assets/images/reciclaje_botellas.png',
            currentPage: previousPage,
            isFirstPage: previousPage == 1,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Transición deslizante desde la izquierda
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  // Acción para el botón de Home
  void _onHomePressed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyInicio(
          cameras: [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              widget.backgroundImagePath,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment
                  .center, // Centrado vertical dentro de la columna
              crossAxisAlignment: CrossAxisAlignment
                  .center, // Centrado horizontal dentro de la columna
              children: [
                FadeTransition(
                  opacity: _titleOpacityAnimation,
                  child: Text(
                    widget.title,
                    textAlign: TextAlign
                        .center, // Centra el texto dentro de su propio espacio
                    style: GoogleFonts.comicNeue(
                      fontSize: 33,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 6.0,
                          color: Colors.black.withOpacity(1),
                          offset: const Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${_countAnimation.value}',
                  textAlign: TextAlign.center, // Centra el texto del contador
                  style: GoogleFonts.comicNeue(
                    fontSize: 90,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(1),
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

          if (_showLottieAnimation)
            Positioned.fill(
              child: Center(
                child: Transform.scale(
                  scale: 1.8,
                  child: Lottie.asset(
                    'assets/animations/fireworks.json',
                    repeat: true,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          if (_showArrowIcon)
            Positioned(
              bottom: 20,
              right: 20,
              child: FadeTransition(
                opacity: _arrowOpacityAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset:
                            const Offset(2, 2), // Desplazamiento del sombreado
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowRight,
                      size: 50,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        _onArrowRightPressed(widget.currentPage + 1),
                  ),
                ),
              ),
            ),
          if (_showArrowIcon)
            Positioned(
              bottom: 20,
              left: 20,
              child: FadeTransition(
                opacity: _arrowOpacityAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset:
                            const Offset(2, 2), // Desplazamiento del sombreado
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      size: 50,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        _onArrowLeftPressed(widget.currentPage - 1),
                  ),
                ),
              ),
            ),

          // Ícono de Home en el centro de las dos flechas
          if (_showArrowIcon)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _arrowOpacityAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(
                              2, 2), // Desplazamiento del sombreado
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.home,
                        size: 50,
                        color: Colors.white,
                      ),
                      onPressed: _onHomePressed,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
