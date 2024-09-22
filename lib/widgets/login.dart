import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/servicios/dynamicLinkService.dart';
import 'register_page.dart';
import '../clases/firestore_service.dart';
import 'inicio.dart';
import 'package:camera/camera.dart';
import 'recuperoPassword.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  final List<CameraDescription>? cameras;
  const LoginApp({super.key, this.cameras});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthenticationWrapper(cameras: cameras),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final List<CameraDescription>? cameras;
  const AuthenticationWrapper({super.key, this.cameras});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return MyInicio(
              cameras: cameras ?? [],
            );
          } else {
            return const LoginPage();
          }
        }
        return Center(
          child: Image.asset(
            'assets/animations/lotti-recycle.json',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _obscurePassword = true; // Estado para mostrar/ocultar contraseña

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        Funciones.SeqLog('information','Iniciando sesión con el email: ${_emailController.text}');
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        final nombreUsuario = await _firestoreService.getUserName(_emailController.text);
        Funciones.SeqLog('information','Sesión iniciada correctamente para el usuario: $nombreUsuario');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MyInicio(
              cameras: [],
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        final message = e.code == 'user-not-found'
            ? 'No se encontró un usuario con ese email.'
            : e.code == 'wrong-password'
                ? 'Contraseña incorrecta.'
                : 'Error en la autenticación.';
        Funciones.SeqLog('error','Error en la autenticación: $message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inicializar Dynamic Links aquí
    DynamicLinkService().initDynamicLinks(context);
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.green.shade200,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 30,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const ImageAsset(),
              ),
              const SizedBox(height: 20.0),
              _buildLoginForm(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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
            obscureText: _obscurePassword, // Controlar visibilidad de la contraseña
            decoration: InputDecoration(
              labelText: 'Contraseña',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese su contraseña';
              }
              return null;
            },
          ),
          const SizedBox(height: 20.0),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _login,
              child: const Text('Iniciar Sesión'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterPage(),
                  ),
                );
              },
              child: const Text('Registrar cuenta'),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecuperoPassword(),
              ),
            );
          },
          child: const Text('¿Olvidaste tu contraseña?'),
        ),
      ],
    );
  }
}

class ImageAsset extends StatelessWidget {
  const ImageAsset({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/playstore.png');
  }
}
