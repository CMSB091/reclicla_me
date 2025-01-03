import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:password_strength/password_strength.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';
import 'package:recila_me/widgets/verificarEmailPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  FirestoreService firebase = FirestoreService();
  bool _isSubmitting = false;
  // Variable para controlar la visibilidad de la contraseña
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<bool> isEmailAlreadyInUse(String email) async {
    try {
      final signInMethods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return signInMethods
          .isNotEmpty; // Si tiene métodos asociados, ya está en uso.
    } catch (e) {
      debugPrint('Error verificando correo: $e');
      return false;
    }
  }

  bool isValidEmail(String email) {
    return EmailValidator.validate(email);
  }

  void _register() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (!isValidEmail(email)) {
      showCustomSnackBar(
          context, 'Por favor ingresa un correo válido.', SnackBarType.error);
      return;
    }

    if (await isEmailAlreadyInUse(email)) {
      showCustomSnackBar(
          context, 'El correo ya está registrado.', SnackBarType.error);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();
        showCustomSnackBar(context, 'Correo de verificación enviado a $email.',
            SnackBarType.confirmation);

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificarEmailPage(user: user),
            ),
          );
        }
      }
    } catch (e) {
      showCustomSnackBar(
          context, 'Error al registrar usuario: $e', SnackBarType.error);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrar Usuario',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 30,
          ),
        ),
        leading: IconButton(
          icon: Image.asset('assets/images/exitDoor.png'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.green.shade200,
      ),
      body: Center(
        child: BlurredBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/agregarUsuario.png',
                    height: 150.0,
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su email';
                      } else if (!EmailValidator.validate(value)) {
                        return 'Por favor ingrese un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? FontAwesomeIcons.eye
                              : FontAwesomeIcons.eyeSlash,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor ingrese su contraseña';
                      } else if (value.length < 8) {
                        return 'Debe tener al menos 8 caracteres';
                      } else if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                        return 'Debe contener al menos una letra mayúscula';
                      } else if (!RegExp(r'(?=.*[!@#\$&*~])').hasMatch(value)) {
                        return 'Debe contener al menos un carácter especial';
                      } else if (estimatePasswordStrength(value) < 0.5) {
                        return 'La contraseña es demasiado débil';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? FontAwesomeIcons.eye
                              : FontAwesomeIcons.eyeSlash,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  _isSubmitting
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const FaIcon(FontAwesomeIcons.registered),
                          label: const Text('Registrar'),
                          onPressed: _register,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
