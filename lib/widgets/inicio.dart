import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/MiniJuegoBasura.dart';
import 'package:recila_me/widgets/ResumenRecicladoScreen.dart';
import 'package:recila_me/widgets/datosPersonales.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/historialPage.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:camera/camera.dart';
import 'package:recila_me/widgets/lottieWidget.dart';
import 'package:recila_me/widgets/mySplashScreen.dart';
import 'package:recila_me/widgets/redSocial.dart';
import 'package:recila_me/widgets/object_detection_screen.dart';
import 'package:recila_me/widgets/resumenes.dart';


import 'noticias.dart';

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
  List<String> materials = [];
  Funciones funciones = Funciones();
  late String ruta;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      emailUsuario = user!.email; // Guardamos el email una vez
      _loadUserName();
      loadMaterials();
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

  void loadMaterials() async {
    materials = await Funciones.getDistinctMaterials(emailUsuario!);
    setState(() {
      if (materials.isNotEmpty) {
        String materialActual = materials.first;
        print('materialActual $materialActual');
        ruta = funciones.materialInfo[materialActual] ??
            'assets/images/empy_trash.png'; // Ruta predeterminada
      } else {
        // Maneja el caso en que no hay materiales
        ruta = 'assets/images/empy_trash.png';
      }
    });
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
                  _buildDrawerItem(
                    context,
                    icon: FontAwesomeIcons.listCheck,
                    text: 'Resumen Reciclaje',
                    page: const ResumenRecicladoScreen(),
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
            child: index == 1 || index == 3 || index == 0
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: buildLottieAnimation(
                          path: index == 1
                              ? 'assets/animations/lottie-recomendations.json'
                              : index == 3
                                  ? 'assets/animations/resumen_animation2.json'
                                  : 'assets/animations/scan_objects.json',
                          width: 125,
                          height: 125,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        index == 1
                            ? 'Recomendaciones'
                            : index == 3
                                ? 'Resumen'
                                : 'Escaneo de Objetos',
                        style: const TextStyle(
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
        return 'Historial de objetos';
      case 3:
        return 'Resumenes';
      default:
        return 'Menú ${index + 1}';
    }
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return const MySplash(
          nextScreen: ObjectDetectionScreen(),
          lottieAnimation: "assets/animations/scan_objects2.json",
        );
      case 1:
        return MySplash(
          nextScreen: NoticiasChatGPT(
            initialPrompt: '',
          ),
          lottieAnimation: "assets/animations/lottie-robot.json",
        );
      case 2:
        return const HistorialPage(
          detectedItem: '',
          initialDescription: '',
        );
      case 3:
        return MySplash(
          nextScreen: ReusableCountSplashScreen(
            backgroundImagePath: ruta,
          ),
          lottieAnimation: "assets/animations/resumen_animation.json",
        );
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
