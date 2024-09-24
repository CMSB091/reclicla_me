import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? user = FirebaseAuth.instance.currentUser;
  List<String> _paises = [];
  List<String> ciudades = [];
  final Funciones funciones = Funciones();
  String? imageUrl;

  // Para seleccionar una imagen
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarPaises();
    _loadUserProfileImage();
  }

  Future<void> _loadUserProfileImage() async {
    try {
      String? email = widget.correo;
      // Aquí deberías agregar la lógica para recuperar la URL de la imagen desde Firestore o Firebase Storage.
      // Ejemplo: desde Firestore
      final String? userImage =
          await _firestoreService.getUserProfileImage(email);
      setState(() {
        imageUrl = userImage;
      });
    } catch (e) {
      Funciones.SeqLog('error', 'Error al cargar la imagen del perfil: $e');
    }
  }

  // Función para seleccionar y subir una nueva imagen
  Future<void> _pickAndUploadImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      try {
        // Subir la imagen a Firebase Storage
        final ref = _storage.ref().child('user_images/${widget.correo}.jpg');
        await ref.putFile(File(pickedImage.path));

        // Obtener la URL de la imagen subida
        final downloadUrl = await ref.getDownloadURL();

        // Actualizar la imagen en Firestore o donde la almacenes
        await _firestoreService.updateUserProfileImage(
            widget.correo, downloadUrl);

        setState(() {
          imageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Imagen de perfil actualizada correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la imagen: $e')),
        );
      }
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

    setState(() {
      _paisController.text = selectedPais!;
      // Establecer el campo de ciudad en nulo o vacío cuando se selecciona un nuevo país
      _ciudadController.text = '';
    });

    // Carga ciudades para el país seleccionado
    try {
      ciudades = await _firestoreService.getCiudadesPorPais(selectedPais!);
      Funciones.SeqLog('information', 'Ciudades cargadas: $ciudades');
      _mostrarSeleccionCiudad(ciudades); // Muestra la lista de ciudades
    } catch (e) {
      Funciones.SeqLog('error', 'Error al cargar ciudades: $e');
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

    setState(() {
      _ciudadController.text = selectedCiudad!;
    });
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
        bool result = await _firestoreService.updateUser(nombre, apellido, edad,
            direccion, ciudad, pais, telefono, widget.correo);

        if (result && mounted) {
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

  Future<void> _cargarDatosUsuario() async {
    setState(() {
      _isLoadingData = true;
      _loadingMessage = 'Cargando datos...';
    });

    try {
      if (user != null) {
        String correo = user!.email.toString();
        Map<String, dynamic>? userData =
            await _firestoreService.getUserData(correo);

        _nombreController.text = userData!['nombre'] ?? '';
        _apellidoController.text = userData['apellido'] ?? '';
        _edadController.text = (userData['edad'] ?? '').toString();
        _direccionController.text = userData['direccion'] ?? '';
        _ciudadController.text = userData['ciudad'] ?? '';
        _paisController.text = userData['pais'] ?? '';
        _telefonoController.text = userData['telefono'] ?? '';
        ciudades =
            await _firestoreService.getCiudadesPorPais(_paisController.text);
      } else {
        await Funciones.SeqLog('information', 'No hay un usuario autenticado');
      }
    } catch (e) {
      await Funciones.SeqLog('error', 'Error al cargar datos del usuario: $e');
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool isNumber = false,
    bool isReadOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1), // Fondo oscuro con opacidad
        borderRadius: BorderRadius.circular(10.0), // Bordes redondeados
      ),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        onTap: onTap,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(
            color: Colors.black, // Color oscuro para el label
          ),
          filled: true,
          fillColor:
              Colors.black.withOpacity(0.1), // Fondo oscuro para el campo
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: Colors.black, // Borde oscuro
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: Colors.green, // Color del borde cuando está enfocado
            ),
          ),
        ),
        style: const TextStyle(
          color: Colors.black, // Color del texto dentro del campo
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingresa tu $labelText';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
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
      body: BlurredBackground(
        blurStrength: 20.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center the content
                children: [
                  // Centered Avatar with edit icon
                  Stack(
                    alignment: Alignment
                        .bottomRight, // Position the icon at the bottom right
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl!)
                            : const AssetImage(
                                    'assets/images/perfil.png')
                                as ImageProvider,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.plusCircle,
                            color: Colors.green),
                        onPressed: _pickAndUploadImage, // Handle image change
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 20), // Add some space between image and TextField

                  // Name TextField
                  _buildTextField(
                    controller: _nombreController,
                    labelText: 'Nombre',
                  ),
                  // Other fields
                  _buildTextField(
                    controller: _apellidoController,
                    labelText: 'Apellido',
                  ),
                  _buildTextField(
                    controller: _edadController,
                    labelText: 'Edad',
                    isNumber: true,
                  ),
                  _buildTextField(
                    controller: _direccionController,
                    labelText: 'Dirección',
                  ),
                  GestureDetector(
                    onTap: _mostrarSeleccionPais,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: _paisController,
                        labelText: 'País',
                        isReadOnly: true,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_paisController.text.isNotEmpty) {
                        _mostrarSeleccionCiudad(ciudades);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Selecciona un país primero.')),
                        );
                      }
                    },
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: _ciudadController,
                        labelText: 'Ciudad',
                        isReadOnly: true,
                      ),
                    ),
                  ),
                  _buildTextField(
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _guardarDatos,
              icon: const FaIcon(FontAwesomeIcons.save), // Save icon
              label: const Text('Guardar'),
            ),
            if (widget.desdeInicio)
              ElevatedButton.icon(
                onPressed: _eliminarDatos,
                icon: const FaIcon(FontAwesomeIcons.trash), // Delete icon
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
