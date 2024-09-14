import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/datos_personales.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:recila_me/clases/object_detection_screen.dart';
import 'package:camera/camera.dart';
import 'package:recila_me/widgets/lottie_widget.dart';
import 'package:recila_me/widgets/noticias.dart';

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
  final Funciones funciones = Funciones();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (user != null) {
      setState(() {
        isLoading = true;
      });

      final nombre = await _firestoreService.getUserName(user!.email.toString());
      setState(() {
        nombreUsuario = nombre;
        isLoading = false;
      });
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
        await funciones.log('error','Error al cerrar sesión: $e');
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
            ? null // No mostrar título cuando se está cargando
            : Text(
                'Bienvenido $nombreUsuario !!',
                style: const TextStyle(
                  fontFamily: 'Artwork',
                  fontSize: 18,
                ),
              ),
        leading: IconButton(
          icon: Image.asset('assets/images/exitDoor.png'),
          onPressed: () => _simulateLogout(context),
        ),
      ),
      endDrawer: _buildDrawer(context),
      body: Center(
        child: isLoading
            ? buildLottieAnimation(
                path: 'assets/animations/lotti-recycle.json', // Ruta de tu archivo Lottie
                width: 500, // Ajusta el tamaño según tus necesidades
                height: 500, // Ajusta el tamaño según tus necesidades
              )
            : Wrap(
                spacing: 20.0,
                runSpacing: 20.0,
                children: List.generate(4, (index) {
                  return _buildMenuCard(context, index);
                }),
              ),
      ),
    );
  }
  Widget _buildDrawer(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.50,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildDrawerHeader(),
            _buildDrawerItem(
              context,
              icon: Icons.info,
              text: 'Información',
              page: DatosPersonales(correo: user!.email.toString(), desdeInicio: true, cameras: widget.cameras),
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
    return GestureDetector(
      onTap: () {
        if (!_isCancelled && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      child: SizedBox(
        width: 150.0,
        height: 150.0,
        child: Card(
          color: Colors.green.shade100,
          child: Center(
            child: Text(
              _getMenuTitle(index),
              style: const TextStyle(
                fontSize: 20,
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
        if (widget.cameras.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No se encontraron cámaras disponibles')),
          );
        }
        return ObjectDetectionScreen(cameras: widget.cameras);
      case 1:
        return const NoticiasChatGPT();
      case 2:
        return const Page3();
      case 3:
        return const Page4();
      default:
        return MyInicio(cameras: widget.cameras);
    }
  }
}

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página 2'),
      ),
      body: const Center(
        child: Text('Contenido de la Página 2'),
      ),
    );
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
