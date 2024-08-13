import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../clases/firestore_service.dart';
import 'datos_personales.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isWaitingForVerification = false;
  bool _isSubmitting = false;

  // Método para registrar un nuevo usuario
  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSubmitting) return; // Evitar múltiples envíos

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Verificar si el email ya existe
      bool emailExists = await _firestoreService.checkEmailExists(_emailController.text);

      if (emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El email ya está registrado')),
        );
        return; // Detener el proceso de registro
      }

      // Registrar el nuevo usuario en Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          setState(() {
            _isWaitingForVerification = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se ha enviado un correo de verificación. Por favor revisa tu bandeja de entrada.'),
            ),
          );
          _waitForEmailVerification(user);
        } else {
          // El usuario ya está verificado
          _proceedToNextPage();
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'El email ya está registrado';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil';
      } else {
        message = 'Error en la autenticación: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // Captura y manejo de excepciones
      print('Error en registro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Hubo un problema al registrar el usuario')),
      );
    } finally {
      setState(() {
        _isSubmitting = false; // Permitir nuevo envío
      });
    }
  }

  // Método para esperar la verificación del correo electrónico
  void _waitForEmailVerification(User user) async {
    while (!user.emailVerified) {
      await Future.delayed(const Duration(seconds: 5));
      await user.reload();
      user = FirebaseAuth.instance.currentUser!;
    }
    setState(() {
      _isWaitingForVerification = false;
    });
    _proceedToNextPage();
  }

  // Método para proceder a la siguiente página
  void _proceedToNextPage() async {
    bool registered = await _firestoreService.createUser(
      _emailController.text,
      _passwordController.text,
    );

    if (registered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );
      await Future.delayed(const Duration(seconds: 3));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DatosPersonales(
            _emailController.text,
            correo: _emailController.text, // Pasar el correo a DatosPersonales
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo registrar el usuario')),
      );
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
        backgroundColor: Colors.green.shade200, // Establece el color de fondo aquí
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Añadir la imagen aquí
                Image.asset(
                  'assets/images/agregarUsuario.png', // Reemplaza con la ruta de tu imagen
                  height: 150.0, // Ajusta la altura según sea necesario
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
                      return 'Por favor ingrese un email válido'; // Mensaje si el email no es válido
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor ingrese su contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _isWaitingForVerification ? null : _register,
                        child: const Text('Registrar'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
