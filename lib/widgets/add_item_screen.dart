import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart'; // Para seleccionar imagen desde la galería

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>(); // Para usar en los SnackBar
  String? _description;
  String? _contact;
  File? _imageFile;
  String? _userEmail; // Permite que sea null hasta que se cargue el email
  late String _titulo;
  FirestoreService firestoreService = FirestoreService();

    @override
  void initState() {
    super.initState();
    loadEmail(); // Cargar el email del usuario logueado
  }

  void loadEmail() async {
    String? email = await firestoreService.loadUserEmail();
    if (email != null) {
      setState(() {
        _userEmail = email;
      });
    } else {
      // Manejo del caso cuando el email es null
      print('No se pudo cargar el email del usuario.');
    }
  }

  // Función para seleccionar una imagen de la galería
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path); // Asignar el archivo seleccionado
      });
      Funciones.SeqLog(
          'information', 'Imagen seleccionada: ${_imageFile!.path}');
    } else {
      showSnackBar('No se seleccionó ninguna imagen.');
    }
  }

  // Función para mostrar SnackBar
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Función para manejar la subida de la imagen
  void _handleUpload() {
    if (_formKey.currentState?.validate() != true) {
      showSnackBar('Por favor, completa los campos correctamente.');
      return;
    }

    if (_imageFile == null) {
      showSnackBar('Por favor, selecciona una imagen primero.');
      return;
    }

    _formKey.currentState?.save();

    // Llamar a la función de subir imagen que está en el archivo separado
    if (_userEmail != null) {
      firestoreService
          .uploadImageAndSaveToFirestore(
              imageFile: _imageFile!,
              description: _description!,
              contact: _contact!,
              scaffoldKey: _scaffoldKey,
              email: _userEmail!, // Solo usar si no es null
              titulo: _titulo)
          .then((_) {
        // Limpiar el formulario y la imagen seleccionada después de la subida
        setState(() {
          _description = null;
          _contact = null;
          _imageFile = null;
        });
        _formKey.currentState?.reset();
      });
    } else {
      showSnackBar('No se pudo cargar el email del usuario.');
    }
  }

  // Función reutilizable para InputDecoration
  InputDecoration buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: Colors.black, // Color oscuro para el label
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.1), // Fondo oscuro para el campo
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Clave para mostrar los SnackBars
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context); // Acción de regresar
          },
        ),
        title: const Text(
          'Agregar Artículo',
          style: TextStyle(fontFamily: 'Artwork', fontSize: 18),
        ),
        backgroundColor: Colors.green.shade200,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: buildInputDecoration('Título'),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un encabezado' : null,
                onSaved: (value) => _titulo = value!,
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: buildInputDecoration('Descripción'),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese una descripción' : null,
                onSaved: (value) => _description = value,
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: buildInputDecoration('Contacto'), // Usar función
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un contacto' : null,
                onSaved: (value) => _contact = value,
              ),
              const SizedBox(height: 20),
              _imageFile == null
                  ? const Text('No se ha seleccionado ninguna imagen.')
                  : Image.file(_imageFile!, height: 200),
              ElevatedButton(
                onPressed: _pickImageFromGallery,
                child: const Text('Seleccionar Imagen desde Galería'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleUpload,
                child: const Text('Subir Imagen y Guardar en Firestore'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
