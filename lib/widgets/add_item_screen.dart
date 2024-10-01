import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recila_me/clases/firestore_service.dart'; // Para seleccionar imagen desde la galería


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
  FirestoreService firestoreService = FirestoreService();

  // Función para seleccionar una imagen de la galería
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path); // Asignar el archivo seleccionado
      });
      print('Imagen seleccionada: ${_imageFile!.path}');
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
    firestoreService.uploadImageAndSaveToFirestore(
      imageFile: _imageFile!,
      description: _description!,
      contact: _contact!,
      scaffoldKey: _scaffoldKey,
    ).then((_) {
      // Limpiar el formulario y la imagen seleccionada después de la subida
      setState(() {
        _description = null;
        _contact = null;
        _imageFile = null;
      });
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Clave para mostrar los SnackBars
      appBar: AppBar(
        title: const Text('Agregar Artículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) => value!.isEmpty ? 'Ingrese una descripción' : null,
                onSaved: (value) => _description = value,
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Contacto'),
                validator: (value) => value!.isEmpty ? 'Ingrese un contacto' : null,
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
