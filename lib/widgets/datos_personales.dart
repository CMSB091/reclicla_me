import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/inicio.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:camera/camera.dart';  

class DatosPersonales extends StatelessWidget {
  final String correo;
  final bool desdeInicio;
  final List<CameraDescription> cameras;

  const DatosPersonales({
    super.key,
    required this.correo,
    required this.desdeInicio,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulario de Datos Personales',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DatosPersonalesPage(
        correo: correo,
        desdeInicio: desdeInicio,
        cameras: cameras,
      ),
    );
  }
}

class DatosPersonalesPage extends StatefulWidget {
  final String correo;
  final bool desdeInicio;
  final List<CameraDescription> cameras;

  const DatosPersonalesPage({
    super.key,
    required this.correo,
    required this.desdeInicio,
    required this.cameras,
  });

  @override
  _DatosPersonalesPageState createState() => _DatosPersonalesPageState();
}

class _DatosPersonalesPageState extends State<DatosPersonalesPage> {
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
  final FirestoreService _firestoreService = FirestoreService(); 
  User? user = FirebaseAuth.instance.currentUser;
  List<String> _paises = [];
  List<String> ciudades = [];
  final Funciones funciones = Funciones();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario(); 
    _cargarPaises();
  }

  Future<void> _cargarPaises() async {
    try {
      List<String> paises = await _firestoreService.getPaises();
      setState(() {
        _paises = paises;
        Funciones.SeqLog('information',paises);
      });
    } catch (e) {
      Funciones.SeqLog('error','Error al cargar países: $e');
    }
  }

  void _mostrarSeleccionPais() async {
    String? selectedPais = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona tu país'),
          content: SizedBox(
            width: 100,
            height: 300,
            child: ListView(
              children: _paises.map((pais) {
                return ListTile(
                  title: Text(pais),
                  contentPadding: const EdgeInsets.symmetric(vertical: 1.0),
                  onTap: () {
                    Navigator.of(context).pop(pais);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedPais != null) {
      setState(() {
        _paisController.text = selectedPais;
        // Establecer el campo de ciudad en nulo o vacío cuando se selecciona un nuevo país
      _ciudadController.text = '';  // Aquí puedes usar '' si prefieres mostrarlo vacío en lugar de null
      });

      // Cargar ciudades para el país seleccionado
      try {
        ciudades = await _firestoreService.getCiudadesPorPais(selectedPais);
        Funciones.SeqLog('information','Ciudades cargadas: $ciudades');
        _mostrarSeleccionCiudad(ciudades);  // Muestra la lista de ciudades
      } catch (e) {
        Funciones.SeqLog('error','Error al cargar ciudades: $e');
      }
    }
  }

  void _mostrarSeleccionCiudad(List<String> ciudades) async {
    String? selectedCiudad = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona tu ciudad'),
          content: SizedBox(
            width: 100,
            height: 300,
            child: ListView(
              children: ciudades.map((ciudad) {
                return ListTile(
                  title: Text(ciudad),
                  onTap: () {
                    Navigator.of(context).pop(ciudad);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedCiudad != null) {
      setState(() {
        _ciudadController.text = selectedCiudad;
      });
    }
  }

  void _guardarDatos() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Guardando datos...';
      });

      try {
        String nombre = _nombreController.text;
        String apellido = _apellidoController.text;
        int edad = int.parse(_edadController.text);
        String direccion = _direccionController.text;
        String ciudad = _ciudadController.text;
        String pais = _paisController.text;
        String telefono = _telefonoController.text;
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

        if (result /*&& mounted*/) {
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyInicio(
                            cameras: widget.cameras,
                          ),
                        ),
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar los datos.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });

        _nombreController.clear();
        _apellidoController.clear();
        _edadController.clear();
        _direccionController.clear();
        _ciudadController.clear();
        _paisController.clear();
        _telefonoController.clear();
      }
    }
  }

  void _eliminarDatos() async {
    bool confirmarEliminar = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); 
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmarEliminar) {
      _pedirContrasenaYEliminarCuenta();
    }
  }

  void _intentarSalir() {
    if (!widget.desdeInicio &&
        (_nombreController.text.isNotEmpty ||
            _apellidoController.text.isNotEmpty ||
            _edadController.text.isNotEmpty ||
            _direccionController.text.isNotEmpty ||
            _ciudadController.text.isNotEmpty ||
            _paisController.text.isNotEmpty ||
            _telefonoController.text.isNotEmpty)) {
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
                      builder: (context) => MyInicio(
                        cameras: widget.cameras,
                      ),
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyInicio(
            cameras: widget.cameras,
          ),
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
      if (user != null) {
        String correo = user!.email.toString();
        Map<String, dynamic>? userData = await _firestoreService.getUserData(correo);

        if (userData != null) {
          _nombreController.text = userData['nombre'] ?? '';
          _apellidoController.text = userData['apellido'] ?? '';
          _edadController.text = (userData['edad'] ?? '').toString();
          _direccionController.text = userData['direccion'] ?? '';
          _ciudadController.text = userData['ciudad'] ?? '';
          _paisController.text = userData['pais'] ?? '';
          _telefonoController.text = userData['telefono'] ?? '';
          ciudades = await _firestoreService.getCiudadesPorPais(_paisController.text);
        } else {
          Funciones.SeqLog('information','No se encontraron datos para el usuario con correo $correo');
        }
      } else {
        await Funciones.SeqLog('information','No hay un usuario autenticado');
      }
    } catch (e) {
      await Funciones.SeqLog('error','Error al cargar datos del usuario: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pedirContrasenaYEliminarCuenta() async {
    final TextEditingController contrasenaController = TextEditingController();
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
                controller: contrasenaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            if(widget.desdeInicio)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); 
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmarEliminar == true) {
      showDialog(
        context: context,
        barrierDismissible: false, 
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
            AuthCredential credential = EmailAuthProvider.credential(
              email: user.email!,
              password: contrasenaController.text,
            );
            await user.reauthenticateWithCredential(credential);
            await user.delete();
            if (mounted) {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Cuenta Eliminada'),
                    content: const Text('Tu cuenta ha sido eliminada correctamente.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginApp()), 
                            (route) => false, 
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
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    print('Desde Inicio: ${widget.desdeInicio}'); // Añadir esto para depurar
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
                    GestureDetector(
                      onTap: _mostrarSeleccionPais,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _paisController,
                          decoration: const InputDecoration(
                            labelText: 'País',
                            suffixIcon: Icon(Icons.arrow_drop_down), // Icono de flecha hacia abajo
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu país';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        if (_paisController.text.isNotEmpty) {
                          _mostrarSeleccionCiudad(ciudades);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Selecciona un país primero.')),
                          );
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _ciudadController,
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                            suffixIcon: Icon(Icons.arrow_drop_down), // Icono de flecha hacia abajo
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu ciudad';
                            }
                            return null;
                          },
                        ),
                      ),
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
                  const SizedBox(height: 16),
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
