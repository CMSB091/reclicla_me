import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/buildTextField.dart';
import 'package:recila_me/widgets/lottieWidget.dart';

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

  @override
  void initState() {
    super.initState();
    _setupTextListeners();
  }

  void _setupTextListeners() {
    // Agregamos listeners a los controladores para actualizar la UI dinámicamente
    _nombreController.addListener(() => setState(() {}));
    _apellidoController.addListener(() => setState(() {}));
    _comentariosController.addListener(() => setState(() {}));
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
              _mostrarModalDeAyuda(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  onPressed: _submitFeedback,
                  icon: const FaIcon(FontAwesomeIcons.paperPlane),
                  label: const Text('Enviar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 24.0,
                    ),
                    backgroundColor: Colors.green.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Animación y GIF colocados en fila
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildLottieAnimation(
                    path: 'assets/animations/lottie-eva.json', // Animación 1
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 150.0,
                    fit: BoxFit.contain,
                    repetir: true,
                  ),
                  Image.asset(
                    'assets/images/wall_e_no_bg.gif', // Ruta del GIF
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
    );
  }

  void _mostrarModalDeAyuda(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ayuda'),
          content: const Text(
            'Esta es la sección de comentarios donde puedes compartir tus ideas y opiniones.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _submitFeedback() {
    final String nombre = _nombreController.text.trim();
    final String apellido = _apellidoController.text.trim();
    final String comentarios = _comentariosController.text.trim();

    if (nombre.isEmpty || apellido.isEmpty || comentarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos antes de enviar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Aquí puedes manejar el envío de los comentarios a tu base de datos o backend
    print('Feedback enviado: $nombre $apellido - $comentarios');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Comentarios enviados con éxito!'),
        backgroundColor: Colors.green,
      ),
    );

    // Limpia los campos después de enviar
    _nombreController.clear();
    _apellidoController.clear();
    _comentariosController.clear();
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
