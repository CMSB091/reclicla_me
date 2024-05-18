import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recila_me/inicio.dart';

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light
        ),
        backgroundColor: Colors.green.shade200,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18
        ),
        title: const Text(
          'LOGIN'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Image.asset('assets/playstore.png'), // Aquí puedes colocar tu logo
              ),
              const SizedBox(height: 20.0),
              // Formulario de inicio de sesión
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Campo de email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor ingrese su email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20.0),
                    // Campo de contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor ingrese su contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20.0),
                    // Botón de inicio de sesión
                    ElevatedButton(
                      onPressed: () {
                        final route = MaterialPageRoute(
                          builder: (_)=> myInicio(),
                        );
                        // Esta función se ejecutará cuando se presione el botón de inicio de sesión
                        // Puedes colocar aquí la lógica de autenticación
                        // Por ejemplo, validar el correo electrónico y la contraseña, y luego navegar a la siguiente pantalla
                        if (_formKey.currentState!.validate()) {
                          // Realizar la autenticación aquí
                          // Por ahora, simplemente imprimimos los valores
                          print('Email: ${_emailController.text}');
                          print('Contraseña: ${_passwordController.text}');

                          // Luego puedes navegar a la siguiente pantalla, por ejemplo:
                          Navigator.push(
                            context, route
                          );
                        }
                      },
                      child: const Text('Iniciar Sesión'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
