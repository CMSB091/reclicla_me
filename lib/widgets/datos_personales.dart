import 'package:flutter/material.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/widgets/inicio.dart';

class DatosPersonales extends StatelessWidget {
  final String correo;

  const DatosPersonales(String s, {
    super.key,
    required this.correo,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulario de Datos Personales',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(correo: correo),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String correo;

  const MyHomePage({
    Key? key,
    required this.correo,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService(); // Instancia del servicio Firestore

  void _guardarDatos() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(seconds: 3), () async {
        setState(() {
          _isLoading = false;
        });

        String nombre = _nombreController.text;
        String apellido = _apellidoController.text;
        int edad = int.parse(_edadController.text);
        String direccion = _direccionController.text;
        String ciudad = _ciudadController.text;
        String pais = _paisController.text;
        String telefono = _telefonoController.text;

        // Llamar a updateUser en FirestoreService para actualizar los datos
        // ignore: unused_local_variable
        bool result = await _firestoreService.updateUser(
          nombre,
          apellido,
          edad,
          direccion,
          ciudad,
          pais,
          telefono,
          widget.correo
        );

        // Mostrar el diálogo con los datos ingresados
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Datos Guardados'),
              content: Text(
                  'Nombre: $nombre\nApellido: $apellido\nEdad: $edad\nDirección: $direccion\nCiudad: $ciudad\nPaís: $pais\nTeléfono: $telefono'),
              actions: [
                TextButton(
                  onPressed: () {
                    // Redirigir a la página de inicio
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyInicio('',parametro: nombre,),
                      ),
                    );
                  },
                  child: const Text('OK'),
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
        _ciudadController.clear();
        _paisController.clear();
        _telefonoController.clear();
      });
    }
  }

  void _intentarSalir() {
    if (_nombreController.text.isNotEmpty ||
        _apellidoController.text.isNotEmpty ||
        _edadController.text.isNotEmpty ||
        _direccionController.text.isNotEmpty ||
        _ciudadController.text.isNotEmpty ||
        _paisController.text.isNotEmpty ||
        _telefonoController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Datos sin guardar'),
            content: const Text('Hay datos sin guardar. ¿Desea salir de todas formas?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Salir'),
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
        title: const Text(
          'Datos Personales',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 30,
          ),
        ),
        backgroundColor: Colors.green.shade200,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apellidoController,
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _edadController,
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ciudadController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu ciudad';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _paisController,
                      decoration: const InputDecoration(
                        labelText: 'País',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu país';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu teléfono';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _guardarDatos,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.5),
            ),
          if (_isLoading)
            const Center(
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
    _ciudadController.dispose();
    _paisController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
}
