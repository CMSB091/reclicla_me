import 'package:flutter/material.dart';

class DatosPersonales extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulario de Datos Personales',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  bool _isLoading = false;

  void _guardarDatos() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          _isLoading = false;
        });

        String nombre = _nombreController.text;
        String apellido = _apellidoController.text;
        int edad = int.parse(_edadController.text);
        String direccion = _direccionController.text;

        // Mostrar el diálogo con los datos ingresados
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Datos Guardados'),
              content: Text('Nombre: $nombre\nApellido: $apellido\nEdad: $edad\nDirección: $direccion'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );

        // Limpiar los campos de texto
        _nombreController.clear();
        _apellidoController.clear();
        _edadController.clear();
        _direccionController.clear();
      });
    }
  }

  void _intentarSalir() {
    if (_nombreController.text.isNotEmpty ||
        _apellidoController.text.isNotEmpty ||
        _edadController.text.isNotEmpty ||
        _direccionController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Datos sin guardar'),
            content: Text('Hay datos sin guardar. ¿Desea salir de todas formas?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('Salir'),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset('assets/images/exitDoor.png'),
          onPressed: _intentarSalir,
        ),
        title: Text('Formulario de Datos Personales'),
        backgroundColor: Colors.green.shade200, // Cambiar el color del AppBar a verde limón
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidoController,
                    decoration: InputDecoration(
                      labelText: 'Apellido',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu apellido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _edadController,
                    decoration: InputDecoration(
                      labelText: 'Edad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu edad';
                      }
                      int? edad = int.tryParse(value);
                      if (edad == null || edad < 1 || edad > 99) {
                        return 'Por favor ingresa un número entre 1 y 99';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _direccionController,
                    decoration: InputDecoration(
                      labelText: 'Dirección',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu dirección';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _guardarDatos,
                    child: Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.5),
            ),
          if (_isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Guardando datos...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _edadController.dispose();
    _direccionController.dispose();
    super.dispose();
  }
}
