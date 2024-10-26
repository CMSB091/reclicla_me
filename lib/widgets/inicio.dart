import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/MiniJuegoBasura.dart';
import 'package:recila_me/widgets/datosPersonales.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:camera/camera.dart';
import 'package:recila_me/widgets/lottieWidget.dart';
import 'package:recila_me/widgets/mySplashScreen.dart';
import 'package:recila_me/widgets/redSocial.dart';
import 'package:recila_me/widgets/object_detection_screen.dart';

class MyInicio extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MyInicio({super.key, required this.cameras});

  @override
  _MyInicioState createState() => _MyInicioState();
}

class _MyInicioState extends State<MyInicio> {
  bool _isCancelled = false;
  bool isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();
  User? user = FirebaseAuth.instance.currentUser;
  String? nombreUsuario;
  String? emailUsuario;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      emailUsuario = user!.email; // Guardamos el email una vez
      _loadUserName();
    }
  }

  Future<void> _loadUserName() async {
    if (emailUsuario != null) {
      setState(() {
        isLoading = true;
      });

      try {
        final nombre = await _firestoreService.getUserName(emailUsuario!);
        if (mounted && !_isCancelled) {
          setState(() {
            nombreUsuario = nombre;
            isLoading = false;
          });
        }
      } catch (e) {
        Funciones.SeqLog('error', 'Error al obtener nombre de usuario: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isCancelled = true;
    super.dispose();
  }

  Future<void> _simulateLogout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(
                'Cerrando sesión...',
                style: TextStyle(
                  fontFamily: 'Artwork',
                  fontSize: 20,
                ),
              ),
            ],
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 3));

    if (!_isCancelled && mounted) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        Funciones.SeqLog('error', 'Error al cerrar sesión: $e');
      } finally {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginApp(),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.green.shade200,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        title: isLoading
            ? null
            : Text(
                'Bienvenido $nombreUsuario !!',
                style: const TextStyle(
                  fontFamily: 'Artwork',
                  fontSize: 20,
                ),
              ),
        leading: IconButton(
          icon: Image.asset('assets/images/exitDoor.png'),
          onPressed: () => _simulateLogout(context),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const FaIcon(FontAwesomeIcons.bars),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: _buildDrawer(context),
      body: BlurredBackground(
        blurStrength: 20.0,
        child: Center(
          child: isLoading
              ? buildLottieAnimation(
                  path: 'assets/animations/lotti-recycle.json',
                  width: 500,
                  height: 500,
                )
              : Wrap(
                  spacing: 20.0,
                  runSpacing: 20.0,
                  children: List.generate(4, (index) {
                    return _buildMenuCard(context, index);
                  }),
                ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.50,
      child: Drawer(
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _buildDrawerItem(
                    context,
                    icon: FontAwesomeIcons.info,
                    text: 'Información',
                    page: DatosPersonales(
                      correo: emailUsuario!,
                      desdeInicio: true,
                      cameras: widget.cameras,
                    ),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: FontAwesomeIcons.gamepad,
                    text: 'Mini Juegos',
                    page: const MiniJuegoBasura(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: FontAwesomeIcons.heart,
                    text: 'Donaciones',
                    page: const HomeScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: kToolbarHeight,
      color: Colors.green.shade200,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: const Text(
        'Menú',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontFamily: 'Artwork',
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () {
        if (!_isCancelled && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, int index) {
    final page = _getPageForIndex(index);

    return SizedBox(
      width: 180.0,
      height: 180.0,
      child: Card(
        color: Colors.green.shade100,
        elevation: 5.0,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10.0),
          onTap: () {
            if (!_isCancelled && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            }
          },
          child: Center(
            child: index == 1
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: buildLottieAnimation(
                          path:'assets/animations/lottie-recomendations.json',
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Recomendaciones',
                        style: TextStyle(
                          fontFamily: 'Artwork',
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _getMenuTitle(index),
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _getMenuTitle(int index) {
    switch (index) {
      case 0:
        return 'Detección de objetos';
      case 1:
        return 'ChatGpt';
      case 2:
        return 'Página 3';
      case 3:
        return 'Página 4';
      default:
        return 'Menú ${index + 1}';
    }
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return const ObjectDetectionScreen();
      case 1:
        return const MySplash();
      case 2:
        return const Page3();
      case 3:
        return const Page4();
      default:
        return MyInicio(cameras: widget.cameras);
    }
  }
}

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página 3'),
      ),
      body: const Center(
        child: Text('Contenido de la Página 3'),
      ),
    );
  }
}

class Page4 extends StatelessWidget {
  const Page4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página 4'),
      ),
      body: const Center(
        child: Text('Contenido de la Página 4'),
      ),
    );
  }
}
