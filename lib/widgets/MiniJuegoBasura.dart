import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/clases/residuos.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/puntajes.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';
import 'package:vibration/vibration.dart';

class MiniJuegoBasura extends StatefulWidget {
  const MiniJuegoBasura({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MiniJuegoBasuraState createState() => _MiniJuegoBasuraState();
}

class _MiniJuegoBasuraState extends State<MiniJuegoBasura> {
  String residuoActual = '';
  String? imagenActual;
  int puntos = 0;
  bool _isGameStarted = false;
  Timer? _timer;
  int _timeLeft = 60; // 60 segundos para el temporizador
  final Random random = Random();
  bool _showSaveButton =
      false; // Controla la visibilidad del botón para guardar puntaje
  Funciones funciones = Funciones();
  Color _puntosColor = Colors.black;
  bool _showCountdown = false;
  String _countdownText = '3'; // Inicializa con "3"
  double _textScale = 3.0;

  @override
  void initState() {
    super.initState();
    generarResiduo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void generarResiduo() {
    final residuo = funciones.generarResiduoAleatorio(Residuos.lista);
    setState(() {
      residuoActual = residuo['tipo'];
      imagenActual = residuo['imagen'];
    });
  }

  void verificarRespuesta(String tipoBasurero) {
    if (!_isGameStarted) return; // No hacer nada si el juego no ha comenzado

    int nuevoPuntos =
        funciones.verificarRespuesta(tipoBasurero, residuoActual, puntos);

    setState(() {
      puntos = nuevoPuntos;
      _puntosColor = tipoBasurero == residuoActual ? Colors.green : Colors.red;

      if (tipoBasurero == residuoActual) {
        generarResiduo();
      } else {
        showCustomSnackBar(
            context, '¡Ups! Basurero incorrecto', SnackBarType.error,
            durationInMilliseconds: 1000);

        try {
          Vibration.vibrate(duration: 100);
        } catch (e) {
          debugPrint('Vibration not available: $e');
        }
      }
    });

    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _puntosColor = Colors.black;
      });
    });
  }

  void _startGame() {
    setState(() {
      _showCountdown = true;
      _countdownText = '3'; // Inicializa el texto
      _textScale = 1.0; // Restablece el escalado
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _countdownText = '2';
        _textScale = 1.5; // Aumenta el tamaño
      });
    })
        .then((_) => Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _textScale = 1.0; // vuelve al tamaño normal
              });
            }))
        .then((_) => Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                _countdownText = '1';
                _textScale = 1.5; // Aumenta el tamaño
              });
            }))
        .then((_) => Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _textScale = 1.0; // Volver al tamaño normal
              });
            }))
        .then((_) => Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                _countdownText = '¡A reciclar!';
                _textScale = 1.5; // Aumentar el tamaño
              });
            }))
        .then((_) => Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _showCountdown = false;
                _isGameStarted = true;
                puntos = 0;
                _timeLeft = 60; // Reiniciar el tiempo
                _showSaveButton = false; // Ocultar el botón de guardar puntaje
              });

              _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setState(() {
                  _timeLeft--;
                  if (_timeLeft <= 0) {
                    timer.cancel();
                    _isGameStarted = false;
                    _showSaveButton =
                        true; // Mostrar el botón para guardar puntaje
                    showCustomSnackBar(context, '¡El tiempo se acabó!',
                        SnackBarType.confirmation);
                  }
                });
              });
            }));
  }

  void _saveScore() async {
    try {
      // Mostrar spinner de carga
      funciones.showLoadingSpinner(context);
      // Obtener puntaje actual
      int currentScore = await firestoreService.getCurrentUserScore(context);
      // Cerrar spinner después de obtener puntaje
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      // Verificar si el puntaje actual es mayor o igual al nuevo puntaje
      if (currentScore >= puntos) {
        bool shouldSave = false;

        // Mostrar confirmación
        if (mounted) {
          shouldSave = await funciones.showConfirmationDialog(context);
        }

        if (!shouldSave) {
          return; // Salir si el usuario decide no guardar
        }
      }

      // Mostrar spinner nuevamente
      if (mounted) {
        funciones.showLoadingSpinner(context);
      }

      // Guardar o actualizar puntaje
      await firestoreService.saveOrUpdateScore(context, puntos);

      // Cerrar spinner y mostrar confirmación
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showCustomSnackBar(
          context,
          '¡Puntaje guardado exitosamente!',
          SnackBarType.confirmation,
          durationInMilliseconds: 1500,
        );
      }
    } catch (e) {
      // Manejo de errores
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showCustomSnackBar(
          context,
          'Error al guardar el puntaje: $e',
          SnackBarType.error,
          durationInMilliseconds: 3000,
        );
      }
      debugPrint('Error al guardar el puntaje: $e');
    }
  }

  Widget _buildBasurero(String tipo, String assetPath) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Ajusta el tamaño según la orientación y el ancho de la pantalla
    final trashBinWidth = min(screenWidth / (isLandscape ? 4.0 : 3.5),
        120.0); // Máximo 120px de ancho
    final trashBinHeight = min(
        screenWidth / (isLandscape ? 3.5 : 3.0), 150.0); // Máximo 150px de alto

    bool isHighlighted = false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: SizedBox(
            width: trashBinWidth,
            height: trashBinHeight,
            child: DragTarget<String>(
              onWillAcceptWithDetails: (data) {
                setState(() {
                  isHighlighted = true;
                });
                return true;
              },
              onLeave: (data) {
                setState(() {
                  isHighlighted = false;
                });
              },
              onAcceptWithDetails: (data) {
                verificarRespuesta(tipo);
                setState(() {
                  isHighlighted = false;
                });
              },
              builder: (BuildContext context, List<String?> candidateData,
                  List<dynamic> rejectedData) {
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isHighlighted
                            ? Colors.lightGreen
                            : Colors.transparent,
                        width: 4.0,
                      ),
                    ),
                    child: Image.asset(
                      assetPath,
                      width: trashBinWidth,
                      height: trashBinHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildResiduoWidget(Map<String, dynamic> residuo) {
    if (residuo['imagen'] is String) {
      return Image.asset(
        residuo['imagen'],
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      );
    } else if (residuo['imagen'] is IconData) {
      return FaIcon(
        residuo['imagen'],
        size: 80,
      );
    } else {
      return Container();
    }
  }

  Future<bool> mostrarConfirmacionGuardado() async {
    return await funciones.showConfirmationDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlurredBackground(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Aprendo Jugando!!',
            style: TextStyle(
              fontFamily: 'Artwork',
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.green.shade200,
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.infoCircle),
              onPressed: () {
                funciones.showGameRules(
                    context,
                    'Reglas del Juego',
                    '1. Arrastra los residuos hacia el basurero correcto (Plástico, Papel, Orgánico, Vidrio o Materiales Peligrosos).\n'
                        '2. Ganas puntos por cada residuo correctamente clasificado.\n'
                        '3. Pierdes puntos por clasificaciones incorrectas.\n'
                        '4. El tiempo es limitado, ¡intenta clasificar tantos residuos como puedas antes de que el tiempo se agote!\n5. Diviértete Aprendiendo!!');
              },
            ),
          ],
        ),
        body: _showCountdown
            ? BlurredBackground(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: TweenAnimationBuilder(
                      key: ValueKey<String>(_countdownText),
                      tween: Tween<double>(begin: 0.5, end: _textScale),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, double scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Text(
                            _countdownText,
                            style: TextStyle(
                              fontSize:
                                  _countdownText == '¡A reciclar!' ? 64 : 120,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Artwork',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Puntos: ',
                        style: TextStyle(
                            fontSize:
                                24), // La palabra "Puntos" siempre en negro
                      ),
                      Text(
                        '$puntos',
                        style: TextStyle(
                            fontSize: 24,
                            color:
                                _puntosColor), // Solo el número cambia de color
                      ),
                      const SizedBox(width: 40),
                      Text(
                        'Tiempo: ${_timeLeft}s',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!_isGameStarted)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const FaIcon(FontAwesomeIcons.flag),
                          onPressed: _startGame,
                          label: const Text('Empezar Juego'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          icon: const FaIcon(FontAwesomeIcons.eye),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PuntajesScreen(),
                              ),
                            );
                          },
                          label: const Text('Ver Puntajes'),
                        )
                      ],
                    ),
                  if (_isGameStarted)
                    Expanded(
                      child: Center(
                        child: Draggable<String>(
                          data: residuoActual,
                          feedback:
                              buildResiduoWidget({'imagen': imagenActual}),
                          childWhenDragging:
                              const FaIcon(FontAwesomeIcons.trashCan, size: 80),
                          child: buildResiduoWidget({'imagen': imagenActual}),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: _buildBasurero('vidrio',
                            'assets/images/miniJuego/green_trash_bin.png'),
                      ),
                      Flexible(
                        child: _buildBasurero('peligrosos',
                            'assets/images/miniJuego/red_trash_bin.png'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: _buildBasurero('papel',
                            'assets/images/miniJuego/blue_trash_bin.png'),
                      ),
                      Flexible(
                        child: _buildBasurero('plastico',
                            'assets/images/miniJuego/yellow_trash_bin.png'),
                      ),
                      Flexible(
                        child: _buildBasurero('organico',
                            'assets/images/miniJuego/maroon_trash_bin.png'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_showSaveButton)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const FaIcon(FontAwesomeIcons.upload),
                          onPressed: _saveScore,
                          label: const Text('Guardar Puntaje'),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}
