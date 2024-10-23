import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recila_me/widgets/mensajeInicio.dart';

class ReciclaMeApp extends StatelessWidget {
  final List<CameraDescription>? cameras;

  const ReciclaMeApp({super.key, this.cameras});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReciclaMe',
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        primarySwatch: Colors.green,
      ),
      home: SplashScreen(cameras: cameras),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;

  const SplashScreen({super.key, this.cameras});

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
          // Navega a la siguiente pantalla cuando la carga está completa
          Navigator.of(_context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => mensajeInicio(widget.cameras), // Pasa las cámaras a la próxima pantalla
            ),
          );
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
          width: screenWidth * 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/reciclaje1.gif',
                width: screenWidth * 0.5, 
                height: screenHeight * 0.3,
              ),
              const SizedBox(height: 20),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'ReciclaMe',
                  style: TextStyle(
                    fontFamily: 'Artwork',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_progress > 0)
                Container(
                  width: screenWidth * 0.6, 
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