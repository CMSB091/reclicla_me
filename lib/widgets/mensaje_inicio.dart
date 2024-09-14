import 'package:flutter/material.dart';
import 'package:recila_me/clases/funciones.dart';
import 'dart:async';
import 'dart:convert';
import 'package:recila_me/widgets/login.dart';
import 'package:camera/camera.dart';

// ignore: camel_case_types
class mensajeInicio extends StatelessWidget {
  final List<CameraDescription>? cameras;

  const mensajeInicio({super.key, this.cameras});

  @override
  Widget build(BuildContext context) {
    return SplashScreen(cameras: cameras);
  }
}

class RecyclingTip {
  final String message;

  RecyclingTip({required this.message});

  factory RecyclingTip.fromJson(Map<String, dynamic> json) {
    return RecyclingTip(
      message: json['message'],
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
  List<RecyclingTip> _tips = [];
  final Funciones funciones = Funciones();

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    try {
      final String data = await DefaultAssetBundle.of(context).loadString('assets/recycling_tips.json');
      final jsonData = json.decode(data);
      _tips = List<RecyclingTip>.from(jsonData.map((x) => RecyclingTip.fromJson(x)));
    } catch (e) {
      await funciones.log('error','Error al cargar los consejos de reciclaje: $e');
    } finally {
      _showWelcomeDialog();
    }
  }

  void _showWelcomeDialog() {
    RecyclingTip random;
    if (_tips.isNotEmpty) {
      random = _tips[DateTime.now().microsecondsSinceEpoch % _tips.length];
    } else {
      random = RecyclingTip(message: "No se pudo cargar el consejo de reciclaje. Inténtalo de nuevo más tarde.");
    }

    showDialog(
      context: context,  // Usar directamente el contexto actual
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/images/branches_border.png'),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.brown,
                      width: 5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/light_bulb.png',
                              width: 60,
                              height: 60,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Consejo del día!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          random.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _navigateToHome();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginApp(cameras: widget.cameras),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFccffcc),
    );
  }
}
