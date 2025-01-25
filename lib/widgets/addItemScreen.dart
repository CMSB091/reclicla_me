// ignore: file_names
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/buildTextField.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/redSocial.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart'; // Para seleccionar imagen desde la galería


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
  // ignore: library_private_types_in_public_api
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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
    if (widget.isEdit) {
      _tituloController.text = widget.titulo ?? '';
      _descriptionController.text = widget.description ?? '';
      _contactController.text = widget.contact ?? '';
    }
  }

  void _loadEmail() async {
    String? email = await firestoreService.loadUserEmail();
    setState(() {
      _userEmail = email;
    });
  }

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

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    } else {
      showCustomSnackBar(
          context, 'No se tomó ninguna foto.', SnackBarType.error);
    }
  }

  Future<void> _handleUpload() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!_formKey.currentState!.validate()) {
        showCustomSnackBar(
          context,
          'Por favor, completa los campos correctamente.',
          SnackBarType.error,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_imageFile == null) {
        showCustomSnackBar(
          context,
          'Por favor, selecciona una imagen primero.',
          SnackBarType.error,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _formKey.currentState!.save();

      // Reducir el peso de la imagen
      final compressedImage = await Funciones().compressImage(_imageFile!);

      // Subir la imagen comprimida
      if (_userEmail != null) {
        int maxIdPub = 0;
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('items')
            .orderBy('idpub', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          maxIdPub = snapshot.docs.first['idpub'];
        }

        int newIdPub = maxIdPub + 1;

        await firestoreService.uploadImageAndSaveToFirestore(
          imageFile: compressedImage,
          description: _descriptionController.text,
          contact: _contactController.text,
          scaffoldKey: _scaffoldKey,
          email: _userEmail!,
          titulo: _tituloController.text,
          estado: false,
          idpub: newIdPub,
        );

        showCustomSnackBar(
          context,
          'Publicado correctamente',
          SnackBarType.confirmation,
        );
        _resetForm();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        showCustomSnackBar(
          context,
          'No se pudo cargar el email del usuario.',
          SnackBarType.error,
        );
      }
    } catch (e) {
      await Funciones.saveDebugInfo('Error en la función _handleUpload $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Confirmación si el campo de contacto tiene un valor
      if (_contactController.text.isNotEmpty) {
        bool? shouldProceed = await _showContactConfirmationDialog();
        if (shouldProceed != true) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      await firestoreService.updatePost(
        widget.itemId!,
        _tituloController.text,
        _descriptionController.text,
        _contactController.text,
        _imageFile?.path, // Ruta del archivo si hay una nueva imagen
        widget.imageUrl, // URL de la imagen anterior
      );

      showCustomSnackBar(context, 'Publicación actualizada correctamente',
          SnackBarType.confirmation);
      _resetForm();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const HomeScreen()), // usar el nombre correcto de la clase
      );
    } catch (e) {
      showCustomSnackBar(
          context, 'Error al actualizar la publicación', SnackBarType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool?> _showContactConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso!'),
        content: const Text(
          'El número de teléfono que has ingresado será visible para todos los usuarios, ¿desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _descriptionController.clear();
      _contactController.clear();
      _tituloController.clear();
      _imageFile = null;
    });
    _formKey.currentState!.reset();
  }

   void _mostrarAyuda(BuildContext context) {
    Funciones.mostrarModalDeAyuda(
      context: context,
      titulo: 'Ayuda',
      mensaje:
          'Agrega una publicación que luego se mostrará en la sección de de artículos disponibles.\nLas publicaciones pueden ser vistas por todos los usuarios de la aplicación',
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
        title: Text(
          widget.isEdit ? 'Editar publicación' : 'Añadir publicación',
          style: const TextStyle(fontFamily: 'Artwork', fontSize: 22),
        ),
        backgroundColor: Colors.green.shade200,
        actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.infoCircle),
              onPressed: () {
                _mostrarAyuda(context);
              },
            ),
          ],
      ),
      
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isLoading,
            child: BlurredBackground(
              blurStrength: 3.0,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) => null, // No obligatorio
                      ),
                      const SizedBox(height: 5),
                      if (widget.isEdit &&
                          _imageFile == null &&
                          widget.imageUrl != null)
                        Image.network(
                          widget.imageUrl!,
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
                      ElevatedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.upload),
                        label: Text(widget.isEdit ? 'Actualizar' : 'Publicar'),
                        onPressed: () {
                          if (widget.isEdit) {
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
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
