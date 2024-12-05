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
  bool _showSaveButton = false; // Controla la visibilidad del botón para guardar puntaje
  Funciones funciones = Funciones();
  Color _puntosColor = Colors.black;
// Comienza en 3
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
// Inicializamos la cuenta regresiva en 3
      _showCountdown = true;
      _countdownText = '3'; // Inicializamos el texto
      _textScale = 1.0; // Restablecemos el escalado
    });

    // Realizar la cuenta regresiva con un Future y un delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _countdownText = '2';
        _textScale = 1.5; // Aumentamos el tamaño
      });
    })
        .then((_) => Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _textScale = 1.0; // Volvemos al tamaño normal
              });
            }))
        .then((_) => Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                _countdownText = '1';
                _textScale = 1.5; // Aumentamos el tamaño
              });
            }))
        .then((_) => Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _textScale = 1.0; // Volvemos al tamaño normal
              });
            }))
        .then((_) => Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                _countdownText = '¡A reciclar!';
                _textScale = 1.5; // Aumentamos el tamaño
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

              // Iniciar el temporizador
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
    // Mostrar el spinner de carga mientras se verifica el puntaje
    funciones.showLoadingSpinner(context);

    try {
      // Obtener el puntaje actual del usuario desde Firestore
      int currentScore = await firestoreService.getCurrentUserScore(context);

      // Cerrar el spinner después de obtener el puntaje si el widget sigue montado
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Verificar si el puntaje actual en la base de datos es mayor o igual al puntaje obtenido en el juego
      if (currentScore >= puntos) {
        bool shouldSave = false;
        // Mostrar el diálogo de confirmación
        if (mounted) {
          shouldSave = await funciones.showConfirmationDialog(context);
        }
        // Si el usuario decide no guardar, retornar
        if (!shouldSave) {
          return;
        }
      }
      if (mounted) {
        // Mostrar el spinner de carga nuevamente mientras se guarda el puntaje
        funciones.showLoadingSpinner(context);

        // Guardar el nuevo puntaje en la base de datos
        await firestoreService.saveOrUpdateScore(context, puntos);
      }
      // Cerrar el spinner una vez que se complete la operación si el widget sigue montado
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Mostrar un snackbar de confirmación
      if (mounted) {
        showCustomSnackBar(
          context,
          '¡Puntaje guardado exitosamente!',
          SnackBarType.confirmation,
          durationInMilliseconds: 1500,
        );
      }
    } catch (e) {
      // Cerrar el spinner en caso de error si el widget sigue montado
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Mostrar un snackbar de error
        showCustomSnackBar(
          context,
          'Error al guardar el puntaje',
          SnackBarType.error,
          durationInMilliseconds: 1500,
        );
      }
    }
  }

  Widget _buildBasurero(String tipo, String assetPath) {
    // Obtenemos el ancho de la pantalla para ajustar el tamaño de las imágenes dinámicamente
    final screenWidth = MediaQuery.of(context).size.width;
    final trashBinWidth =
        screenWidth / 3.5; // Ajustamos el ancho para que entren bien
    final trashBinHeight =
        screenWidth / 3; // Aumentamos el alto para hacerlo más grande

    // Variable para controlar si el basurero está resaltado
    bool isHighlighted = false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 5.0), // Reducimos el espacio entre los basureros
          child: SizedBox(
            width: trashBinWidth, // Mantenemos un ancho ajustado
            height: trashBinHeight, // Aumentamos el alto
            child: DragTarget<String>(
              onWillAcceptWithDetails: (data) {
                // Resaltar el basurero al pasar el residuo por encima
                setState(() {
                  isHighlighted = true;
                });
                return true;
              },
              onLeave: (data) {
                // Dejar de resaltar si el residuo se aleja
                setState(() {
                  isHighlighted = false;
                });
              },
              onAcceptWithDetails: (data) {
                // Verificar si el residuo es el correcto y dejar de resaltar
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
                            : Colors.transparent, // Resaltar con borde verde
                        width: 4.0,
                      ),
                    ),
                    child: Image.asset(
                      assetPath, // Ruta de la imagen del basurero
                      width: trashBinWidth, // Ajuste del ancho
                      height: trashBinHeight, // Ajuste del alto
                      fit: BoxFit.contain, // Ajusta cómo se adapta la imagen
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
      // Si es una ruta de imagen (String), mostramos la imagen desde assets
      return Image.asset(
        residuo['imagen'],
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      );
    } else if (residuo['imagen'] is IconData) {
      // Si es un ícono (como FontAwesome), lo mostramos
      return FaIcon(
        residuo['imagen'],
        size: 80,
      );
    } else {
      return Container(); // Devolvemos un widget vacío si no es imagen ni ícono
    }
  }

  Future<bool> mostrarConfirmacionGuardado() async {
    return await funciones.showConfirmationDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Mini Juego de Residuos',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade200,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.info),
            onPressed: () {
              funciones.showGameRules(context,'Reglas del Juego','1. Arrastra los residuos hacia el basurero correcto (Plástico, Papel, Orgánico, Vidrio o Materiales Peligrosos).\n'
              '2. Ganas puntos por cada residuo correctamente clasificado.\n'
              '3. Pierdes puntos por clasificaciones incorrectas.\n'
              '4. El tiempo es limitado, ¡intenta clasificar tantos residuos como puedas antes de que el tiempo se agote!\n5. Diviértete Aprendiendo!!'); // Mostrar las reglas del juego
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
                // Mostrar puntos y tiempo restante
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Puntos: ',
                      style: TextStyle(
                          fontSize: 24), // La palabra "Puntos" siempre en negro
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
                // Mostrar botón de empezar si el juego no ha comenzado
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
                        feedback: buildResiduoWidget({
                          'imagen': imagenActual
                        }), // Usamos la función para construir el widget adecuado
                        childWhenDragging:
                            const FaIcon(FontAwesomeIcons.trashCan, size: 80),
                        child: buildResiduoWidget({
                          'imagen': imagenActual
                        }), // Mostramos el widget según el residuo actual
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                // Primera fila de basureros: Metales y Vidrio
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBasurero('vidrio',
                        'assets/images/miniJuego/green_trash_bin.png'),
                    _buildBasurero('peligrosos',
                        'assets/images/miniJuego/red_trash_bin.png'),
                  ],
                ),
                const SizedBox(height: 20),
                // Basureros centrados con tamaño ajustado
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Los centramos manualmente
                  children: [
                    _buildBasurero(
                        'papel', 'assets/images/miniJuego/blue_trash_bin.png'),
                    _buildBasurero('plastico',
                        'assets/images/miniJuego/yellow_trash_bin.png'),
                    _buildBasurero('organico',
                        'assets/images/miniJuego/maroon_trash_bin.png'),
                  ],
                ),
                const SizedBox(height: 20),
                // Mostrar botón de guardar puntaje si el juego terminó
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
    );
  }
}
