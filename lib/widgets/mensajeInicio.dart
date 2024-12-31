import 'package:flutter/material.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:camera/camera.dart';

// ignore: camel_case_types
class mensajeInicio extends StatelessWidget {
  final List<CameraDescription>? cameras;
  final String tipMessage;

  const mensajeInicio(this.cameras, {super.key, required this.tipMessage});

  @override
  Widget build(BuildContext context) {
    return SplashScreen(cameras: cameras, tipMessage: tipMessage);
  }
}

class SplashScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final String tipMessage;

  const SplashScreen({super.key, this.cameras, required this.tipMessage});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
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
                              'Consejo Útil!',
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
                          widget.tipMessage,
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
