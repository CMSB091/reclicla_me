import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final List<Map<String, dynamic>> residuos = [
    {'imagen': FontAwesomeIcons.wineBottle, 'tipo': 'plastico'},
    {'imagen': FontAwesomeIcons.bagShopping, 'tipo': 'plastico'},
    {'imagen': FontAwesomeIcons.utensils, 'tipo': 'plastico'},
    {'imagen': FontAwesomeIcons.prescriptionBottle, 'tipo': 'plastico'},
    {'imagen': FontAwesomeIcons.newspaper, 'tipo': 'papel'},
    {'imagen': FontAwesomeIcons.book, 'tipo': 'papel'},
    {'imagen': FontAwesomeIcons.file, 'tipo': 'papel'},
    {'imagen': FontAwesomeIcons.envelope, 'tipo': 'papel'},
    {'imagen': FontAwesomeIcons.appleWhole, 'tipo': 'organico'},
    {'imagen': FontAwesomeIcons.carrot, 'tipo': 'organico'},
  ];

  String residuoActual = '';
  IconData? iconoActual;
  int puntos = 0;
  bool _isGameStarted = false;
  Timer? _timer;
  int _timeLeft = 60; // 60 segundos para el temporizador
  final Random random = Random();
  bool _showSaveButton = false; // Controla la visibilidad del botón para guardar puntaje
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
      iconoActual = residuo['imagen'];
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
      _timeLeft = 10; // Reiniciar el tiempo
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

  Widget _buildBasurero(Color color, String tipo) {
    return DragTarget<String>(
      builder: (BuildContext context, List<String?> candidateData,
          List<dynamic> rejectedData) {
        return Container(
          width: 100,
          height: 100,
          color: color,
          child: const Center(
            child: FaIcon(FontAwesomeIcons.trash,
                size: 50, color: Colors.white), // FaIcon centrado
          ),
        );
      },
      onAcceptWithDetails: (data) {
        verificarRespuesta(tipo);
      },
    );
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
        
        mainAxisAlignment: MainAxisAlignment.center, // Centrar los basureros verticalmente
        crossAxisAlignment: CrossAxisAlignment.center, // Centrar los basureros horizontalmente
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
            ElevatedButton(
              onPressed: _startGame,
              child: const Text('Empezar Juego'),
            ),
          if (_isGameStarted) // Mostrar cuando el juego está activo
            Expanded(
              child: Center(
                child: Draggable<String>(
                  data: residuoActual,
                  feedback: FaIcon(iconoActual, size: 80),
                  childWhenDragging: const FaIcon(FontAwesomeIcons.trashCan, size: 80),
                  child: FaIcon(iconoActual, size: 80),
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Basureros centrados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBasurero(Colors.blue, 'papel'),
              _buildBasurero(Colors.yellow, 'plastico'),
              _buildBasurero(Colors.brown, 'organico'),
            ],
          ),
          const SizedBox(height: 20),
          // Mostrar botón de guardar puntaje si el juego terminó
          if (_showSaveButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _saveScore,
                  child: const Text('Guardar Puntaje'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PuntajesScreen(),
                      ),
                    );
                  },
                  child: const Text('Ver Puntajes'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
