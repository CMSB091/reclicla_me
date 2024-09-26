import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MiniJuegoBasura extends StatefulWidget {
  const MiniJuegoBasura({Key? key}) : super(key: key);

  @override
  _MiniJuegoBasuraState createState() => _MiniJuegoBasuraState();
}

class _MiniJuegoBasuraState extends State<MiniJuegoBasura> {
  final List<Map<String, dynamic>> residuos = [
    // Plásticos
    {
      'imagen': FontAwesomeIcons.wineBottle,
      'tipo': 'plastico'
    }, // Botella de plástico
    {
      'imagen': FontAwesomeIcons.bagShopping,
      'tipo': 'plastico'
    }, // Bolsa de plástico
    {
      'imagen': FontAwesomeIcons.utensils,
      'tipo': 'plastico'
    }, // Cubiertos de plástico
    {
      'imagen': FontAwesomeIcons.prescriptionBottle,
      'tipo': 'plastico'
    }, // Botella de plástico (medicamentos)

    // Papel
    {'imagen': FontAwesomeIcons.newspaper, 'tipo': 'papel'}, // Periódico
    {'imagen': FontAwesomeIcons.book, 'tipo': 'papel'}, // Libro
    {'imagen': FontAwesomeIcons.file, 'tipo': 'papel'}, // Hoja de papel
    {'imagen': FontAwesomeIcons.envelope, 'tipo': 'papel'}, // Sobre de papel

    // Orgánicos
    {
      'imagen': FontAwesomeIcons.appleWhole,
      'tipo': 'organico'
    }, // Fruta (manzana)
    {
      'imagen': FontAwesomeIcons.carrot,
      'tipo': 'organico'
    }, // Verdura (zanahoria)
  ];

  String residuoActual = '';
  IconData? iconoActual;
  int puntos = 0;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    generarResiduoAleatorio();
  }

  void generarResiduoAleatorio() {
    final residuo = residuos[random.nextInt(residuos.length)];
    setState(() {
      residuoActual = residuo['tipo'];
      iconoActual = residuo['imagen'];
    });
  }

  void verificarRespuesta(String tipoBasurero) {
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

  Widget _buildBasurero(Color color, String tipo) {
    return DragTarget<String>(
      builder: (BuildContext context, List<String?> candidateData,
          List<dynamic> rejectedData) {
        return Container(
          width: 100,
          height: 100,
          color: color,
          child: const Center(
            // Asegura que el ícono esté centrado dentro del contenedor
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
        title: const Text('Mini Juego de Residuos'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Centrar los basureros verticalmente
        crossAxisAlignment:
            CrossAxisAlignment.center, // Centrar los basureros horizontalmente
        children: [
          Text('Puntos: $puntos',
              style: const TextStyle(fontSize: 24)), // Mostrar puntaje
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Draggable<String>(
                data: residuoActual,
                feedback: FaIcon(iconoActual, size: 80),
                childWhenDragging:
                    const FaIcon(FontAwesomeIcons.trashCan, size: 80),
                child: FaIcon(iconoActual, size: 80),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Basureros centrados
          Row(
            mainAxisAlignment: MainAxisAlignment
                .spaceEvenly, // Espacio igual entre los basureros
            children: [
              _buildBasurero(Colors.blue, 'papel'),
              _buildBasurero(Colors.yellow, 'plastico'),
              _buildBasurero(Colors.brown, 'organico'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
