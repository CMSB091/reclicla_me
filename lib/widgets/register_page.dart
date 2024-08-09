import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
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

  // Método para registrar un nuevo usuario
  void _register() async {
    try {
      if (_formKey.currentState!.validate()) {
        // Verificar si el email ya existe
        bool emailExists = await _firestoreService.checkEmailExists(_emailController.text);

        if (emailExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El email ya está registrado')),
          );
          return; // Detener el proceso de registro
        }

        // Registrar el nuevo usuario
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
                _emailController.text, correo: _emailController.text, // Pasar el correo a DatosPersonales
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No se pudo registrar el usuario')),
          );
        }
      }
    } catch (e) {
      // Captura y manejo de excepciones
      print('Error en registro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Hubo un problema al registrar el usuario')),
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
                ElevatedButton(
                  onPressed: _register,
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
