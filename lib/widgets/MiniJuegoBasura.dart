import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/puntajes.dart';

class MiniJuegoBasura extends StatefulWidget {
  const MiniJuegoBasura({super.key});

  @override
  _MiniJuegoBasuraState createState() => _MiniJuegoBasuraState();
}

class _MiniJuegoBasuraState extends State<MiniJuegoBasura> {
  // Lista de residuos con rutas a las imágenes PNG
  final List<Map<String, dynamic>> residuos = [
    {
      'imagen':
          'assets/images/miniJuego/animatedBottle.png', // Ruta a la imagen en assets
      'tipo': 'plastico'
    },
    {
      'imagen': 'assets/images/miniJuego/glassBottle.png',
      'tipo': 'vidrio'
    },
    {
      'imagen': 'assets/images/miniJuego/can.png',
      'tipo': 'plastico'
    },
    /*{
      'imagen': 'assets/images/prescriptionBottle.png',
      'tipo': 'plastico'
    },
    {
      'imagen': 'assets/images/newspaper.png',
      'tipo': 'papel'
    },
    {
      'imagen': 'assets/images/book.png',
      'tipo': 'papel'
    },
    {
      'imagen': 'assets/images/file.png',
      'tipo': 'papel'
    },
    {
      'imagen': 'assets/images/envelope.png',
      'tipo': 'papel'
    },
    {
      'imagen': 'assets/images/appleWhole.png',
      'tipo': 'organico'
    },
    {
      'imagen': 'assets/images/carrot.png',
      'tipo': 'organico'
    },*/
  ];

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

  @override
  void initState() {
    super.initState();
    generarResiduoAleatorio();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void generarResiduoAleatorio() {
    final residuo = residuos[random.nextInt(residuos.length)];
    setState(() {
      residuoActual = residuo['tipo'];
      imagenActual = residuo['imagen'];
    });
  }

  void verificarRespuesta(String tipoBasurero) {
    if (!_isGameStarted) return; // No hacer nada si el juego no ha comenzado
    if (tipoBasurero == residuoActual) {
      setState(() {
        puntos += 1; // Sumar un punto si es correcto
        generarResiduoAleatorio();
      });
    } else {
      setState(() {
        puntos -= 1; // Restar un punto si es incorrecto
        if (puntos < 0) puntos = 0; // Evitar puntos negativos
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Ups! Basurero incorrecto')),
      );
    }
  }

  void _startGame() {
    setState(() {
      _isGameStarted = true;
      puntos = 0;
      _timeLeft = 20; // Reiniciar el tiempo
      _showSaveButton = false; // Ocultar el botón de guardar puntaje
    });

    // Iniciar el temporizador
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          timer.cancel();
          _isGameStarted = false;
          _showSaveButton = true; // Mostrar el botón para guardar puntaje
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡El tiempo se acabó!')),
          );
        }
      });
    });
  }

  void _saveScore() {
    // Invocar la función de Firestore para guardar o actualizar el puntaje
    firestoreService.saveOrUpdateScore(context, puntos);
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
              funciones.showGameRules(context); // Mostrar las reglas del juego
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mostrar puntos y tiempo restante
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Puntos: $puntos', style: const TextStyle(fontSize: 24)),
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
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.flag),
              onPressed: _startGame,
              label: const Text('Empezar Juego'),
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
              _buildBasurero('vidrio', 'assets/images/miniJuego/green_trash_bin.png'),
              _buildBasurero('peligrosos', 'assets/images/miniJuego/red_trash_bin.png'),
            ],
          ),
          const SizedBox(height: 20),
          // Basureros centrados con tamaño ajustado
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Los centramos manualmente
            children: [
              _buildBasurero('papel', 'assets/images/miniJuego/blue_trash_bin.png'),
              _buildBasurero('plastico', 'assets/images/miniJuego/yellow_trash_bin.png'),
              _buildBasurero('organico', 'assets/images/miniJuego/maroon_trash_bin.png'),
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
                ),
              ],
            ),
        ],
      ),
    );
  }
}
