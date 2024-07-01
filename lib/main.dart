import 'package:firebase_core/firebase_core.dart';
import 'package:recila_me/mensaje_inicio.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recicla Me',
      theme: ThemeData(
        primaryColor: Colors.green.shade200,
        hintColor: Colors.green.shade300,
      ),
      home: const ReciclaMeApp(),
    );
  }
}

class ReciclaMeApp extends StatelessWidget {
  const ReciclaMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReciclaMe',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),
    );
  }
}

/* En esta seccion se carga la página de inicio con la imagen gif y la barra de carga */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0;
  late BuildContext _context;

  @override
  void initState() {
    super.initState();
    _context = context;
    Timer(const Duration(seconds: 2), _startLoading);
  }

  void _startLoading() {
    Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {
      setState(() {
        if (_progress >= 1) {
          timer.cancel();
          // Navegar a la siguiente pantalla cuando la carga está completa
          Navigator.of(_context).pushReplacement(
              MaterialPageRoute(builder: (context) => const mensajeInicio()));
        } else {
          _progress += 0.02;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFccffcc), // Fondo verde muy claro
      body: Center(
        child: SizedBox(
          width: screenWidth * 0.8, // Ajusta el ancho según el ancho de la pantalla
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/reciclaje1.gif',
                width: screenWidth * 0.5, // Ajusta el ancho según el ancho de la pantalla
                height: screenHeight * 0.3, // Ajusta la altura según el alto de la pantalla
              ),
              const SizedBox(height: 20),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'ReciclaMe',
                  style: TextStyle(
                    fontFamily: 'Artwork', // Asegúrate de tener la fuente añadida
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_progress > 0)
                Container(
                  width: screenWidth * 0.6, // Ajusta el ancho según el ancho de la pantalla
                  height: 20, // Altura de la barra de progreso
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300], // Color de fondo de la barra de progreso
                  ),
                  child: Stack(
                    children: [
                      // Fondo de la barra de progreso
                      Container(
                        width: _progress * (screenWidth * 0.6), // Ancho de llenado de la barra de progreso
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.green, // Color de llenado de la barra de progreso
                        ),
                      ),
                      // Porcentaje de carga
                      Center(
                        child: Text(
                          '${(_progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


