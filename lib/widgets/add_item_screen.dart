import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/build_text_field.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart'; // Para seleccionar imagen desde la galería

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

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
  FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadEmail();
    _setupTextListeners();
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
        _resetForm();
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

  // Campo de texto reutilizable
  Widget _buildTextField({
    required String labelText,
    required TextEditingController controller,
    required int maxLength,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          decoration: buildInputDecoration(labelText),
          validator: validator,
          maxLines: null,
          keyboardType: keyboardType,
          inputFormatters:
              inputFormatters ?? [LengthLimitingTextInputFormatter(maxLength)],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${controller.text.length}/$maxLength',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
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
        title: const Text(
          'Agregar Artículo',
          style: TextStyle(fontFamily: 'Artwork', fontSize: 18),
        ),
        backgroundColor: Colors.green.shade200,
      ),
      body: BlurredBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  labelText: 'Título',
                  controller: _tituloController,
                  maxLength: 20,
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese un título' : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  labelText: 'Descripción',
                  controller: _descriptionController,
                  maxLength: 100,
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese una descripción' : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  labelText: 'Contacto',
                  controller: _contactController,
                  maxLength: 15,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese un contacto' : null,
                ),
                const SizedBox(height: 20),
                _imageFile == null
                    ? const Text('No se ha seleccionado ninguna imagen.')
                    : Image.file(_imageFile!, height: 200),
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
                        onPressed: _handleUpload,
                        icon: const FaIcon(FontAwesomeIcons.upload),
                        label: const Text('Subir Imagen'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
