import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/datos_personales.dart';
import 'package:recila_me/clases/firestore_service.dart'; // Importa tu servicio de Firestore

class CustomIcons {
  static const IconData customInfo = IconData(0xe900, fontFamily: 'CustomIcons');
}

class MyInicio extends StatelessWidget {
  final String parametro; // Se declara como final para asegurar inmutabilidad
  final Funciones funciones = Funciones(); // Crea una instancia de la clase
  final FirestoreService firestoreService = FirestoreService(); // Instancia de FirestoreService
  User? user = FirebaseAuth.instance.currentUser;

  MyInicio(String s, {super.key, required this.parametro}); // Constructor que recibe el parámetro como final

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: firestoreService.getUserData(user!.email.toString()), // Llama a getUserData
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Lottie.asset('assets/animations/lotti-recycle.json'),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        // Extraer el nombre del Map
        String userName = snapshot.data?['nombre'] ?? parametro;

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
            title: Text(
              'Bienvenido $userName !!',
              style: const TextStyle(
                fontFamily: 'Artwork',
                fontSize: 18,
              ),
            ),
            leading: IconButton(
              icon: Image.asset('assets/images/exitDoor.png'),
              onPressed: () => funciones.simulateLogout(context),
            ),
          ),
          endDrawer: _buildDrawer(context),
          body: Center(
            child: Wrap(
              spacing: 20.0,
              runSpacing: 20.0,
              children: List.generate(4, (index) {
                return _buildMenuCard(context, index);
              }),
            ),
          ),
        );
      },
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
              icon: const Icon(Icons.info), // Utiliza un icono del sistema
              text: 'Información',
              page: DatosPersonales('',correo: parametro, desdeInicio: true), // Pasa el parámetro al constructor
            ),
            // Agrega más ListTile aquí si tienes más opciones en el menú
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
    required Widget icon, // Cambia IconData a Widget
    required String text,
    required Widget page,
  }) {
    return ListTile(
      leading: icon, // Usa el widget icon directamente
      title: Text(text),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, int index) {
    final page = _getPageForIndex(index);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: SizedBox(
        width: 150.0,
        height: 150.0,
        child: Card(
          color: Colors.green.shade100,
          child: Center(
            child: Text(
              'Menú ${index + 1}',
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

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return const Page1();
      case 1:
        return const Page2();
      case 2:
        return const Page3();
      case 3:
        return const Page4();
      default:
        return MyInicio('',parametro: parametro); // Asegúrate de pasar el parámetro correcto
    }
  }
}

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página 1'),
      ),
      body: const Center(
        child: Text('Contenido de la Página 1'),
      ),
    );
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
