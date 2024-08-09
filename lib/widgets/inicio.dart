import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recila_me/widgets/datos_personales.dart';
import 'package:recila_me/widgets/login.dart';

class MyInicio extends StatelessWidget {
  final String parametro;

  const MyInicio(String s, {super.key, required this.parametro});
  void _simulateLogout(BuildContext context) async {
    // Muestra el diálogo de cierre de sesión
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar el diálogo tocando fuera de él
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Cerrando sesión...',
              style: TextStyle(
                fontFamily: 'Artwork',
                fontSize: 20,
              ),),
            ],
          ),
        );
      },
    );

    // Simula el cierre de sesión
    await Future.delayed(const Duration(seconds: 3));

    // Cierra el diálogo
    Navigator.of(context, rootNavigator: true).pop();

    // Redirige a la página de login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginApp(), // Asegúrate de tener la ruta a la página de login
      ),
    );
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
        title: Text('Bienvenido $parametro !!',
        style: const TextStyle(
          fontFamily: 'Artwork',
          fontSize: 22,
        ),),
        leading: IconButton(
          icon: Image.asset('assets/images/exitDoor.png'),
          onPressed: () {
            _simulateLogout(context); // Llama a la función para simular el cierre de sesión
          },
        ),
      ),
      endDrawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.40, // 40% de la pantalla
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                height: kToolbarHeight, // Altura estándar del AppBar (56 píxeles)
                color: Colors.green.shade200,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  'Menú',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Artwork', // Mismo tamaño que el texto del AppBar
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Información',),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DatosPersonales('', correo: 'marcelo@gmail.com',), // Página de edición
                    ),
                  );
                },
              ),
              // Agrega más ListTile aquí si tienes más opciones en el menú
            ],
          ),
        ),
      ),
      body: Center(
        child: Wrap(
          spacing: 20.0, // Espacio horizontal entre tarjetas
          runSpacing: 20.0, // Espacio vertical entre tarjetas
          children: List.generate(4, (index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      switch (index) {
                        case 0:
                          return Page1();
                        case 1:
                          return Page2();
                        case 2:
                          return Page3();
                        case 3:
                          return Page4();
                        default:
                          return MyInicio('', parametro: parametro,); // Regresa a la página principal por defecto
                      }
                    },
                  ),
                );
              },
              child: SizedBox(
                width: 150.0, // Ancho de cada tarjeta
                height: 150.0, // Alto de cada tarjeta
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
          }),
        ),
      ),
    );
  }
}

class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página 1'),
      ),
      body: Center(
        child: Text('Contenido de la Página 1'),
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página 2'),
      ),
      body: const Center(
        child: Text('Contenido de la Página 2'),
      ),
    );
  }
}

class Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página 3'),
      ),
      body: const Center(
        child: Text('Contenido de la Página 3'),
      ),
    );
  }
}

class Page4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página 4'),
      ),
      body: Center(
        child: Text('Contenido de la Página 4'),
      ),
    );
  }
}
