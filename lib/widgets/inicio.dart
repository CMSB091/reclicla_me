import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    home: MyInicio(),
    routes: {
      '/page1': (context) => Page1(),
      '/page2': (context) => Page2(),
      '/page3': (context) => Page3(),
      '/page4': (context) => Page4(),
    },
  ));
}

class MyInicio extends StatelessWidget {
  const MyInicio({super.key});

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
        title: const Text('Bienvenido  !!'),
        leading: IconButton(
          icon: Image.asset('assets/images/exitDoor.png'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Wrap(
          spacing: 20.0, // Espacio horizontal entre tarjetas
          runSpacing: 20.0, // Espacio vertical entre tarjetas
          children: List.generate(4, (index) {
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/page${index + 1}');
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
