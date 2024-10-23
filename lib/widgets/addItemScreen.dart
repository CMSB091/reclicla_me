import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/buildTextField.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/redSocial.dart'; // Para seleccionar imagen desde la galería

class AddItemScreen extends StatefulWidget {
  final String? itemId;
  final String? titulo;
  final String? description;
  final String? contact;
  final String? imageUrl;
  final bool isEdit;

  const AddItemScreen({
    super.key,
    this.itemId,
    this.titulo,
    this.description,
    this.contact,
    this.imageUrl,
    this.isEdit = false, // Por defecto es false si no se pasa el parámetro
  });

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // Controladores para los campos de texto
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  File? _imageFile;
  String? _userEmail;
  bool _isLoading = false;
  String? _imageUrl;
  FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadEmail();
    _setupTextListeners();
    if (widget.isEdit) {
      // Si es modo edición, cargar los datos del artículo en los campos
      _tituloController.text = widget.titulo ?? '';
      _descriptionController.text = widget.description ?? '';
      _contactController.text = widget.contact ?? '';
      _imageUrl = widget.imageUrl;
      print('ImageUrl $_imageUrl');
    }
  }

  // Cargar el email del usuario
  void _loadEmail() async {
    String? email = await firestoreService.loadUserEmail();
    setState(() {
      _userEmail = email;
    });
  }

  // Configurar los listeners para los controladores de texto
  void _setupTextListeners() {
    _tituloController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _contactController.addListener(() => setState(() {}));
  }

  Future<void> _pickImageFromGallery() async {
    File? selectedImage = await Funciones.pickImageFromGallery(context);
    setState(() {
      _imageFile = selectedImage;
    });
  }

  // Función para tomar una foto desde la cámara
  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
      Funciones.SeqLog('information', 'Foto tomada: ${_imageFile!.path}');
    } else {
      _showSnackBar('No se tomó ninguna foto.');
    }
  }

  // Mostrar SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleUpload() async {
    // Mostrar el spinner
    setState(() {
      _isLoading = true;
    });

    try {
      if (!_formKey.currentState!.validate()) {
        Funciones.showSnackBar(
            context, 'Por favor, completa los campos correctamente.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_imageFile == null) {
        Funciones.showSnackBar(
            context, 'Por favor, selecciona una imagen primero.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _formKey.currentState!.save();

      if (_userEmail != null) {
        await firestoreService.uploadImageAndSaveToFirestore(
          imageFile: _imageFile!,
          description: _descriptionController.text,
          contact: _contactController.text,
          scaffoldKey: _scaffoldKey,
          email: _userEmail!,
          titulo: _tituloController.text,
          estado: false,
        );
        Funciones.showSnackBar(context, 'Publicacdo correctamente');
        _resetForm();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const HomeScreen()), // Asegúrate de usar el nombre correcto de la clase
        );
      } else {
        Funciones.showSnackBar(
            context, 'No se pudo cargar el email del usuario.');
      }
    } catch (e) {
      print('Error $e');
    } finally {
      // Ocultar el spinner después de que la operación termine
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePost() async {
    setState(() {
      _isLoading = true; // Mostrar el spinner al comenzar el proceso
    });

    try {
      await firestoreService.updatePost(
        widget.itemId!,
        _tituloController.text,
        _descriptionController.text,
        _contactController.text,
        _imageFile?.path, // Ruta del archivo si hay una nueva imagen
        widget.imageUrl, // URL de la imagen anterior
      );

      // Mostrar mensaje de éxito
      Funciones.showSnackBar(context, 'Publicación actualizada correctamente');

      // Limpiar los campos
      _resetForm();

      // Redirigir a la página de red social
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const HomeScreen()), // Asegúrate de usar el nombre correcto de la clase
      );
    } catch (e) {
      print('Error al actualizar el post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar la publicación')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Ocultar el spinner al finalizar
      });
    }
  }
  // Resetear el formulario después de la subida exitosa
  void _resetForm() {
    setState(() {
      _descriptionController.clear();
      _contactController.clear();
      _tituloController.clear();
      _imageFile = null;
    });
    _formKey.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEdit ? 'Editar publicación' : 'Añadir publicación',
          style: const TextStyle(fontFamily: 'Artwork', fontSize: 25),
        ),
        backgroundColor: Colors.green.shade200,
      ),
      body: BlurredBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                buildTextField(
                  labelText: 'Título',
                  controller: _tituloController,
                  maxLength: 20,
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese un título' : null,
                ),
                const SizedBox(height: 5),
                buildTextField(
                  labelText: 'Descripción',
                  controller: _descriptionController,
                  maxLength: 100,
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese una descripción' : null,
                ),
                const SizedBox(height: 5),
                buildTextField(
                  labelText: 'Contacto',
                  controller: _contactController,
                  maxLength: 15,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese un contacto' : null,
                ),
                const SizedBox(height: 5),
                // Aquí es donde ajustamos qué imagen mostrar
                if (widget.isEdit &&
                    _imageFile == null &&
                    widget.imageUrl != null)
                  Image.network(
                    widget
                        .imageUrl!, // Mostrar la imagen desde la URL si es edición y no hay archivo local
                    height: 300,
                    width: 300,
                  )
                else if (_imageFile != null)
                  Image.file(
                    _imageFile!,
                    height: 300,
                    width: 300,
                  )
                else
                  const Text('No se ha seleccionado ninguna imagen.'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const FaIcon(FontAwesomeIcons.image),
                      label: const Text('Desde Galería'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const FaIcon(FontAwesomeIcons.camera),
                      label: const Text('Tomar Foto'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.upload),
                        label:
                            Text(widget.isEdit ? 'Actualizar' : 'Subir imagen'),
                        onPressed: () {
                          if (widget.isEdit) {
                            // Actualizar en Firebase si es edición
                            _updatePost();
                          } else {
                            _handleUpload();
                          }
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
