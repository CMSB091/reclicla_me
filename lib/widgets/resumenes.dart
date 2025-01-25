import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/ResumenRecicladoScreen.dart';

class ReusableCountSplashScreen extends StatefulWidget {
  final String backgroundImagePath;
  final int currentPage;
  final bool isFirstPage;

  const ReusableCountSplashScreen({
    super.key,
    required this.backgroundImagePath,
    this.currentPage = 1,
    this.isFirstPage = false,
  });

  @override
  // ignore: library_private_types_in_public_api
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
  Funciones funciones = Funciones();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final bool _showLottieAnimation = false;
  bool _showArrowIcon = false;
  List<String> materials = []; // Lista de materiales únicos
  late int cotador;
  late String usuarioMail;
  int contador = 0;
  @override
  void initState() {
    super.initState();
    _initializeUserData(); // Asegura que usuarioMail esté inicializado
    _initializeControllers();

    // Inicializa `_countAnimation` con un valor predeterminado
    _countAnimation = IntTween(begin: 0, end: 0).animate(_countController);

    Funciones.startTitleAnimation(_titleController, _startCountAnimation);
  }

  Future<void> _initializeUserData() async {
    await getUserMail(); // Espera a obtener el correo del usuario antes de continuar
    if (usuarioMail.isNotEmpty) {
      loadMaterials(); // Llama a `loadMaterials` solo cuando `usuarioMail` está disponible
    }
  }

  Future<void> getUserMail() async {
    String? userEmail = await funciones.getCurrentUserEmail();
    if (userEmail != null) {
      setState(() {
        usuarioMail = userEmail;
      });
    }
  }

  void loadMaterials() async {
    materials = await Funciones.getDistinctMaterials(usuarioMail);
    setState(
        () {}); // Actualiza el estado para cargar los materiales en la interfaz

    if (materials.isNotEmpty) {
      // Llama a `_initializeCounter` una vez que `materials` esté completamente cargado
      _initializeCounter();
    }
  }

  void _initializeCounter() async {
    // Verifica que `materials` tenga elementos y que el índice esté en rango
    if (materials.isNotEmpty && widget.currentPage - 1 < materials.length) {
      String material = materials[widget.currentPage - 1];

      // Obtiene el conteo real de manera asíncrona
      int cotador = await displayMaterialCount(material);

      // Ajusta la duración en función del valor final de `cotador` para aumentar la velocidad
      _countController.duration = Duration(
          milliseconds: cotador * 20);

      // Actualiza `_countAnimation` con el valor de `cotador`
      setState(() {
        _countAnimation =
            IntTween(begin: 0, end: cotador).animate(_countController);
      });

      // Inicia la animación del contador
      _countController.forward(from: 0);
    }
  }

  Future<int> displayMaterialCount(String material) async {
    int count = await Funciones.countMaterialInHistorial(material, usuarioMail);
    return count;
  }

  void _initializeControllers() {
    _titleController = AnimationController(vsync: this);
    _countController = AnimationController(vsync: this);
    _arrowController = AnimationController(vsync: this);

    Funciones.initializeAnimations(
        _titleController, _countController, _arrowController, this);

    _titleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

    _arrowOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeIn),
    );
  }

  void _startCountAnimation() {
    Funciones.startCountAnimation(
      _countController,
      _countAnimation,
      () async {
        //await Funciones.playCompletionSound(_audioPlayer);
        await Funciones.vibrateOnCompletion();
        _showFireworks();
      },
      () => setState(() {}),
    );
  }

  void _showFireworks() {
    /*setState(() {
      _showLottieAnimation = true;
    });
*/
    Timer(const Duration(seconds: 3), () {
      setState(() {
        //_showLottieAnimation = false;
        _showArrowIcon = true;
      });
      _arrowController.forward();
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    _titleController.dispose();
    _arrowController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verifica si materials está vacío o si el índice actual está fuera de rango
    String titleText = 'Aún no has reciclado nada...';
    if (materials.isNotEmpty && widget.currentPage - 1 < materials.length) {
      titleText = 'Objetos de ${materials[widget.currentPage - 1]} Reciclados';
      contador += 1;
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(widget.backgroundImagePath, fit: BoxFit.cover),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _titleOpacityAnimation,
                  child: Text(
                    titleText, // Usa el título dinámico comprobado
                    textAlign: TextAlign.center,
                    style: GoogleFonts.comicNeue(
                      fontSize: 40,
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
                if(contador > 0 )
                Text(
                  '${_countAnimation.value}',
                  textAlign: TextAlign.center,
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
          if (_showLottieAnimation && contador > 0)
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
          if (_showArrowIcon && contador > 0)
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
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowRight,
                      size: 50,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (widget.currentPage == materials.length) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResumenRecicladoScreen(),
                          ),
                        );
                      } else {
                        funciones.navigateToNextPage(
                          context,
                          widget.currentPage + 1,
                          materials[widget.currentPage],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          if (_showArrowIcon && widget.currentPage > 1)
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
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      size: 50,
                      color: Colors.white,
                    ),
                    onPressed: () => funciones.navigateToPreviousPage(
                      context,
                      widget.currentPage - 1,
                      materials,
                    ),
                  ),
                ),
              ),
            ),
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
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.house,
                        size: 50,
                        color: Colors.white,
                      ),
                      onPressed: () => Funciones.navigateToHome(context),
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
