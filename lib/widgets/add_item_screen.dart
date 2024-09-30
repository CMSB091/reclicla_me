import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para interactuar con Firestore
import 'package:image_picker/image_picker.dart'; // Para seleccionar imagen desde la galería

class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _description;
  String? _contact;
  File? _imageFile;

  // Función para seleccionar una imagen de la galería
  Future<void> _pickImageFromGallery() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path); // Asignar el archivo seleccionado
      });
      print('Imagen seleccionada: ${_imageFile!.path}');
    } else {
      print('No se seleccionó ninguna imagen.');
    }
  }

  // Función para subir la imagen a Firebase Storage y guardar la URL en Firestore
  Future<void> _uploadImageAndSaveToFirestore() async {
    if (_imageFile == null) {
      print('No hay imagen para subir');
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      print('El formulario no es válido');
      return;
    }

    _formKey.currentState?.save();

    try {
      // Verificar si el archivo existe
      if (!await _imageFile!.exists()) {
        print('El archivo no existe en la ruta especificada: ${_imageFile!.path}');
        return;
      }

      print('El archivo existe, subiendo a Firebase Storage...');

      // Generar una referencia para la imagen en Firebase Storage
      final ref = FirebaseStorage.instance.ref().child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Subir la imagen a Firebase Storage
      UploadTask uploadTask = ref.putFile(_imageFile!);

      // Monitorear el progreso de la subida
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Progreso: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
      }, onError: (e) {
        print('Error durante la subida: $e');
      });

      // Esperar hasta que la subida se complete
      TaskSnapshot taskSnapshot = await uploadTask;
      if (taskSnapshot.state == TaskState.success) {
        // Obtener la URL de descarga solo si la subida fue exitosa
        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen subida: $imageUrl');

        // Guardar los datos en Firestore, en la colección 'items'
        await FirebaseFirestore.instance.collection('items').add({
          'description': _description,
          'contact': _contact,
          'imageUrl': imageUrl, // Guardar la URL de la imagen
        });

        print('Datos guardados correctamente en Firestore.');

        // Mostrar mensaje de éxito o limpiar el formulario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Artículo guardado correctamente')),
        );

      } else {
        print('Error: La subida no fue exitosa.');
      }
    } catch (e) {
      print('Error al subir la imagen y guardar en Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Artículo'),
      ),
      body: SingleChildScrollView( // Añadido para permitir el desplazamiento
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Descripción'),
                validator: (value) => value!.isEmpty ? 'Ingrese una descripción' : null,
                onSaved: (value) => _description = value,
                keyboardType: TextInputType.multiline,
                maxLines: null, // Permite que el campo de texto expanda según sea necesario
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Contacto'),
                validator: (value) => value!.isEmpty ? 'Ingrese un contacto' : null,
                onSaved: (value) => _contact = value,
              ),
              SizedBox(height: 20),
              _imageFile == null
                  ? Text('No se ha seleccionado ninguna imagen.')
                  : Image.file(_imageFile!, height: 200), // Mostrar la imagen cargada
              ElevatedButton(
                onPressed: _pickImageFromGallery, // Cargar imagen desde la galería
                child: Text('Seleccionar Imagen desde Galería'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImageAndSaveToFirestore,
                child: Text('Subir Imagen y Guardar en Firestore'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
