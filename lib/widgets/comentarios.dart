import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/buildTextField.dart';
import 'package:recila_me/widgets/lottieWidget.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';
import 'package:intl/intl.dart';

class Comentarios extends StatefulWidget {
  final String emailUsuario;

  const Comentarios(this.emailUsuario, {super.key});

  @override
  State<Comentarios> createState() => _ComentariosState();
}

class _ComentariosState extends State<Comentarios> {
  // Controladores para los campos
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _comentariosController = TextEditingController();
  String _buildNumber = "Cargando...";

  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupTextListeners();
    _fetchBuildNumber();
  }

  Future<void> _fetchBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _buildNumber = packageInfo.buildNumber;
      debugPrint('hola ${packageInfo.version}');
    });
  }

  void _setupTextListeners() {
    // Agregamos listeners a los controladores para actualizar la UI dinámicamente
    _nombreController.addListener(_validateInputs);
    _apellidoController.addListener(_validateInputs);
    _comentariosController.addListener(_validateInputs);
  }

  void _validateInputs() {
    setState(() {
      _isButtonEnabled = _nombreController.text.trim().isNotEmpty &&
          _apellidoController.text.trim().isNotEmpty &&
          _comentariosController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comentarios',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.green.shade200,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.house, color: Colors.black),
          onPressed: () {
            Funciones.navigateToHome(context);
          },
        ),
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
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Correo del usuario: ${widget.emailUsuario}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  buildTextField(
                    labelText: 'Nombre',
                    controller: _nombreController,
                    maxLength: 50,
                    hint: 'Introduce tu nombre',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    labelText: 'Apellido',
                    controller: _apellidoController,
                    maxLength: 50,
                    hint: 'Introduce tu apellido',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El apellido es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    labelText: 'Comentarios',
                    controller: _comentariosController,
                    maxLength: 500,
                    hint: 'Escribe tus comentarios aquí',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Los comentarios son obligatorios';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isButtonEnabled ? _submitFeedback : null,
                      icon: const FaIcon(FontAwesomeIcons.paperPlane),
                      label: const Text('Enviar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 24.0,
                        ),
                        backgroundColor: _isButtonEnabled
                            ? Colors.green.shade400
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildLottieAnimation(
                        path: 'assets/animations/lottie-eva.json',
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 150.0,
                        fit: BoxFit.contain,
                        repetir: true,
                      ),
                      Image.asset(
                        'assets/images/wall_e_no_bg.gif',
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 150.0,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: buildLottieAnimation(
                  path:
                      'assets/animations/lotti-recycle.json', // Ruta del Lottie spinner
                  width: 500,
                  height: 500,
                  fit: BoxFit.contain,
                  repetir: true,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        color: Colors.green.shade100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Versión: 1.0.0',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              'Build Number: $_buildNumber',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAyuda(BuildContext context) {
    Funciones.mostrarModalDeAyuda(
      context: context,
      titulo: 'Ayuda',
      mensaje:
          'Esta es la sección de comentarios donde puedes compartir tus ideas y opiniones.',
    );
  }

  void _submitFeedback() async {
    final String nombre = _nombreController.text.trim();
    final String apellido = _apellidoController.text.trim();
    final String comentarios = _comentariosController.text.trim();

    if (nombre.isEmpty || apellido.isEmpty || comentarios.isEmpty) {
      showCustomSnackBar(
          context,
          'Por favor, completa todos los campos antes de enviar.',
          SnackBarType.error,
          durationInMilliseconds: 3000);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Dentro de tu función
    String fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Llamar a la función de guardado en Firestore
    bool success = await Funciones.guardarFeedback(
      nombre: nombre,
      apellido: apellido,
      comentarios: comentarios,
      emailUsuario: widget.emailUsuario,
      fecha: fechaFormateada,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      showCustomSnackBar(context, '¡Comentarios enviados con éxito!',
          SnackBarType.confirmation,
          durationInMilliseconds: 3000);

      // Limpia los campos después de enviar
      _nombreController.clear();
      _apellidoController.clear();
      _comentariosController.clear();
    } else {
      showCustomSnackBar(
          context,
          'Hubo un error al enviar los comentarios. Intenta nuevamente.',
          SnackBarType.error,
          durationInMilliseconds: 3000);
    }
  }

  @override
  void dispose() {
    // Limpia los controladores al destruir el widget
    _nombreController.dispose();
    _apellidoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }
}
