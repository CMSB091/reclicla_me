import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';

class RecuperoPassword extends StatefulWidget {
  const RecuperoPassword({super.key});

  @override
  _RecuperoPasswordState createState() => _RecuperoPasswordState();
}

class _RecuperoPasswordState extends State<RecuperoPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _enviarEmailRestablecimiento() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        // Enviar correo de restablecimiento utilizando Firebase Authentication
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text,
        );
        if (context.mounted) {
          showCustomSnackBar(context,'Correo de restablecimiento enviado correctamente.',SnackBarType.confirmation);
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Error al enviar el correo.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No se encontró un usuario con ese correo.';
        }
        if (context.mounted) {
          showCustomSnackBar(context,errorMessage,SnackBarType.error);
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  

  Widget buildLottieAnimation({
    required String path,
    double width = 100.0,
    double height = 100.0,
    BoxFit fit = BoxFit.contain,
    bool repetir = true,
  }) {
    return Lottie.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      repeat: repetir,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset('assets/images/exitDoor.png'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.green.shade200,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 26,
        ),
        title: const Text(
          'Recuperar Contraseña',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 26,
          ),
        ),
      ),
      body: BlurredBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su email';
                    } else if (!EmailValidator.validate(value)) {
                      return 'Por favor ingrese un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _enviarEmailRestablecimiento,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Enviar Enlace de Restablecimiento'),
                ),
                const SizedBox(height: 20),
                buildLottieAnimation(
                  path: 'assets/animations/forgotPassword.json',
                  width: 600.0,
                  height: 600.0,
                  fit: BoxFit.contain,
                  repetir: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 