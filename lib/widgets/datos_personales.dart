import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/build_text_field.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
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
  // ignore: library_private_types_in_public_api
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
  final FirestoreService _firestoreService = FirestoreService();
  User? user = FirebaseAuth.instance.currentUser;
  List<String> _paises = [];
  List<String> ciudades = [];
  String? imageUrl;
  late bool _isLoading = true;
  late bool _isSaving = false;
  final Funciones funciones = Funciones();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await funciones.cargarDatosUsuario(
      user: FirebaseAuth.instance.currentUser,
      nombreController: _nombreController,
      apellidoController: _apellidoController,
      edadController: _edadController,
      direccionController: _direccionController,
      ciudadController: _ciudadController,
      paisController: _paisController,
      telefonoController: _telefonoController,
      setLoadingState: _setLoadingState,
    );
    await _cargarPaises();
    await _loadUserProfileImage();
  }

  void _setLoadingState(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  Future<void> _loadUserProfileImage() async {
    try {
      String? email = widget.correo;
      final String? userImage =
          await _firestoreService.getUserProfileImage(email);
      setState(() {
        imageUrl = userImage;
      });
    } catch (e) {
      Funciones.SeqLog('error', 'Error al cargar la imagen del perfil: $e');
    }
  }

  Future<void> _cargarPaises() async {
    try {
      List<String> paises = await _firestoreService.getPaises();
      setState(() {
        _paises = paises;
        Funciones.SeqLog('information', paises);
      });
    } catch (e) {
      Funciones.SeqLog('error', 'Error al cargar países: $e');
    }
  }

  void _mostrarSeleccionPais() async {
    String? selectedPais = await _mostrarDialogoSeleccion(
      'Selecciona tu país',
      _paises,
    );
    if (selectedPais != null) {
      setState(() {
        _paisController.text = selectedPais;
        _ciudadController
            .clear(); // Limpia el campo de ciudad al cambiar el país
      });
      _mostrarCiudades(selectedPais);
    }
  }

  Future<void> _mostrarCiudades(String pais) async {
    try {
      List<String> ciudades = await _firestoreService.getCiudadesPorPais(pais);
      String? selectedCiudad =
          await _mostrarDialogoSeleccion('Selecciona tu ciudad', ciudades);
      if (selectedCiudad != null) {
        setState(() {
          _ciudadController.text = selectedCiudad;
        });
      }
    } catch (e) {
      Funciones.SeqLog('error', 'Error al cargar ciudades: $e');
    }
  }

  Future<String?> _mostrarDialogoSeleccion(
      String titulo, List<String> items) async {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: SizedBox(
            width: 100,
            height: 300,
            child: ListView(
              children: items.map((item) {
                return ListTile(
                  title: Text(item),
                  onTap: () => Navigator.of(context).pop(item),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _eliminarDatos() async {
    bool confirmarEliminar = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text(
              '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.'),
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
            content: const Text(
                'Hay datos sin guardar. ¿Desea salir de todas formas?'),
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
            if (widget.desdeInicio)
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
      if(mounted){
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
                  Text(
                    'Eliminando cuenta...',
                    style: TextStyle(fontFamily: 'Artwork', fontSize: 18),
                  ),
                ],
              ),
            );
          },
        );
      }

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          bool result =
              await _firestoreService.deleteUser(user.email ?? 'No disponible');
          if (result) {
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
                    content: const Text(
                        'Tu cuenta ha sido eliminada correctamente.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const LoginApp()),
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
                content:
                    Text('Ocurrió un error al intentar eliminar la cuenta: $e'),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: _intentarSalir,
        ),
        title: const Text('Datos Personales',
            style: TextStyle(fontFamily: 'Artwork', fontSize: 30)),
        backgroundColor: Colors.green.shade200,
      ),
      body: Stack(
        children: [
          BlurredBackground(
            blurStrength: 20.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl!)
                                : const AssetImage('assets/images/perfil.png')
                                    as ImageProvider,
                            backgroundColor: Colors.grey.shade200,
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.circlePlus,
                                color: Colors.green),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    funciones.pickAndUploadImage(
                                      correo: widget.correo,
                                      onImageUploaded:
                                          (String uploadedImageUrl) {
                                        setState(() {
                                          imageUrl = uploadedImageUrl;
                                        });
                                      },
                                      context: context,
                                    );
                                  },
                          ),
                          //),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildTextField(
                        controller: _nombreController,
                        labelText: 'Nombre',
                      ),
                      buildTextField(
                        controller: _apellidoController,
                        labelText: 'Apellido',
                      ),
                      buildTextField(
                        controller: _edadController,
                        labelText: 'Edad',
                        isNumber: true,
                      ),
                      buildTextField(
                        controller: _direccionController,
                        labelText: 'Dirección',
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : _mostrarSeleccionPais,
                        child: AbsorbPointer(
                          child: buildTextField(
                            controller: _paisController,
                            labelText: 'País',
                            isReadOnly: true,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!_isLoading && _paisController.text.isNotEmpty) {
                            _mostrarDialogoSeleccion(
                                'Selecciona tu Ciudad', ciudades);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Selecciona un país primero.')),
                            );
                          }
                        },
                        child: AbsorbPointer(
                          child: buildTextField(
                            controller: _ciudadController,
                            labelText: 'Ciudad',
                            isReadOnly: true,
                          ),
                        ),
                      ),
                      buildTextField(
                        controller: _telefonoController,
                        labelText: 'Teléfono',
                        isNumber: true,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Cargando datos...'),
                ],
              ),
            ),
          if (_isSaving)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Guardando datos...'),
                ],
              ),
            )
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading || _isSaving
                  ? null
                  : () {
                      funciones.guardarDatos(
                        correo: widget.correo,
                        nombreController: _nombreController,
                        apellidoController: _apellidoController,
                        edadController: _edadController,
                        direccionController: _direccionController,
                        ciudadController: _ciudadController,
                        paisController: _paisController,
                        telefonoController: _telefonoController,
                        setSavingState: (bool value) {
                          setState(() {
                            _isSaving = value;
                          });
                        },
                        context: context,
                        cameras: widget.cameras,
                      );
                    },
              icon: const FaIcon(FontAwesomeIcons.floppyDisk),
              label: const Text('Guardar'),
            ),
            if (widget.desdeInicio)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _eliminarDatos,
                icon: const FaIcon(FontAwesomeIcons.trash),
                label: const Text('Eliminar'),
              ),
          ],
        ),
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
