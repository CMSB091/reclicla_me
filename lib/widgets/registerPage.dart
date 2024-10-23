import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/widgets/datosPersonales.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';

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
  final TextEditingController _confirmPasswordController =TextEditingController();
  FirestoreService firebase = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;
  // Variable para controlar la visibilidad de la contraseña
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      String email = _emailController.text;
      String password = _passwordController.text;

      try {
        // Verificar si el correo ya existe en la colección 'usuario'
        bool emailExists = await firebase.checkEmailExists(email);
        if (emailExists) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El correo ya está registrado')),
          );
          return;
        }

        // Registrar al usuario en Firebase Authentication
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Si el registro es exitoso, crear el usuario en Firestore
        if (userCredential.user != null) {
          bool userCreated = await firebase.createUser(email);
          if (userCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usuario registrado exitosamente')),
            );
            // Redirigir a la página de DatosPersonales después de registrar
            List<CameraDescription> cameras = await availableCameras();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DatosPersonales(
                  correo: email,
                  desdeInicio: true,
                  cameras: cameras, // Lista de cámaras disponible
                ),
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar usuario: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
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
                      : ElevatedButton(
                          onPressed: _register,
                          child: const Text('Registrar'),
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
