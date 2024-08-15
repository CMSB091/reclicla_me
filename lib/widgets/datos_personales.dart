// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar Firebase Auth
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/widgets/inicio.dart';
import 'package:recila_me/widgets/login.dart';

class DatosPersonales extends StatelessWidget {
  final String correo;
  final bool desdeInicio;

  const DatosPersonales(String s, {
    super.key,
    required this.correo, required this.desdeInicio
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulario de Datos Personales',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(correo: correo, desdeInicio: desdeInicio,),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String correo;
  final bool desdeInicio;

  const MyHomePage({
    super.key,
    required this.correo, required this.desdeInicio,
  });

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
  bool _isLoadingData = false;
  String _loadingMessage = '';
  final FirestoreService _firestoreService = FirestoreService(); // Instancia del servicio Firestore
  User? user = FirebaseAuth.instance.currentUser; // Obtener el usuario autenticado

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario(); // Cargar los datos del usuario al iniciar el estado
  }

  void _guardarDatos() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Guardando datos...';
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
                        builder: (context) => MyInicio(nombre, parametro: nombre,),
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

  void _eliminarDatos() async {
    // Mostrar un modal de confirmación antes de eliminar
    bool confirmarEliminar = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancelar
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmar
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmarEliminar) {
      setState(() {
        _pedirContrasenaYEliminarCuenta();
      });
    }
  }

  void _intentarSalir() {
    if(widget.desdeInicio == false){
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
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  MyInicio('',parametro:user!.email.toString()),
                    ),
                    );
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
    }else{
      Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyInicio('',parametro: '',), // La página a la que quieres redirigir
      ),
      );
    }
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() {
      _isLoadingData = true;
      _loadingMessage = 'Cargando datos...';
    });

    try {
      // Verificar si hay un usuario autenticado
      if (user != null) {
        // Obtener el correo electrónico del usuario autenticado
        String correo = user!.email.toString();

        // Llamar al servicio Firestore para obtener los datos del usuario
        Map<String, dynamic>? userData = await _firestoreService.getUserData(correo);

        if (userData != null) {
          _nombreController.text = userData['nombre'] ?? '';
          _apellidoController.text = userData['apellido'] ?? '';
          _edadController.text = (userData['edad'] ?? '').toString();
          _direccionController.text = userData['direccion'] ?? '';
          _ciudadController.text = userData['ciudad'] ?? '';
          _paisController.text = userData['pais'] ?? '';
          _telefonoController.text = userData['telefono'] ?? '';
        } else {
          // Manejar el caso en el que no se obtienen datos
          print('No se encontraron datos para el usuario con correo $correo');
        }
      } else {
        // Manejar el caso en el que no hay un usuario autenticado
        print('No hay un usuario autenticado');
      }
    } catch (e) {
      // Manejar errores en la carga de datos
      print('Error al cargar datos del usuario: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pedirContrasenaYEliminarCuenta() async {
    final TextEditingController _contrasenaController = TextEditingController();
    bool? confirmarEliminar = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Para eliminar tu cuenta, ingresa tu contraseña:'),
              TextField(
                controller: _contrasenaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancelar
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmar
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmarEliminar == true) {
      // Mostrar el spinner mientras se elimina la cuenta
      showDialog(
        context: context,
        barrierDismissible: false, // El usuario no puede cerrar el diálogo tocando fuera de él
        builder: (context) {
          return const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Eliminando cuenta...',
                style: TextStyle(
                    fontFamily: 'Artwork',
                    fontSize: 18
                ),),
              ],
            ),
          );
        },
      );

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          bool result = await _firestoreService.deleteUser(user.email ?? 'No disponible');
          if(result){
            // Reautenticar al usuario con la contraseña ingresada
            AuthCredential credential = EmailAuthProvider.credential(
              email: user.email!,
              password: _contrasenaController.text,
            );
            await user.reauthenticateWithCredential(credential);
            // Eliminar la cuenta
            await user.delete();
            // Cerrar el diálogo del spinner
            Navigator.of(context).pop();
            // Mostrar un diálogo de éxito
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Cuenta Eliminada'),
                  content: const Text('Tu cuenta ha sido eliminada correctamente.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cerrar el diálogo
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginApp()), // Redirigir a la página de inicio de sesión
                          (route) => false, // Eliminar todas las rutas anteriores
                        );
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        }
      } catch (e) {
        // Cerrar el diálogo del spinner
        Navigator.of(context).pop();
        // Manejar errores en la reautenticación o eliminación de cuenta
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Ocurrió un error al intentar eliminar la cuenta: $e'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _guardarDatos,
                          child: const Text('Guardar'),
                        ),
                        if(widget.desdeInicio)
                        ElevatedButton(
                          onPressed: _eliminarDatos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading || _isLoadingData)
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.5),
            ),
          if (_isLoading || _isLoadingData)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    _loadingMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
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
