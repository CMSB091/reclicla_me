import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/datosPersonales.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';

class VerificarEmailPage extends StatefulWidget {
  final User user;

  const VerificarEmailPage({Key? key, required this.user}) : super(key: key);

  @override
  _VerificarEmailPageState createState() => _VerificarEmailPageState();
}

class _VerificarEmailPageState extends State<VerificarEmailPage> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    try {
      setState(() {
        _isChecking = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      await user?.reload(); // Refrescar el estado del usuario actual
      final updatedUser = FirebaseAuth.instance.currentUser;

      debugPrint('Estado de emailVerified: ${updatedUser?.emailVerified}');

      if (updatedUser?.emailVerified == true) {
        debugPrint('Correo verificado exitosamente.');

        showCustomSnackBar(context, 'Correo verificado exitosamente.',
            SnackBarType.confirmation);

        // Crear usuario en Firestore
        final bool userCreated =
            await FirestoreService().createUser(updatedUser!.email!);

        if (!userCreated) {
          showCustomSnackBar(
              context,
              'Error al crear usuario en Firestore. Inténtalo de nuevo.',
              SnackBarType.error);
          setState(() {
            _isChecking = false;
          });
          return;
        }

        // Obtener cámaras antes de redirigir
        final cameras = await availableCameras();

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DatosPersonales(
                correo: updatedUser.email!,
                desdeInicio: true,
                cameras: cameras,
              ),
            ),
          );
          debugPrint('Redirigiendo a DatosPersonales...');
        }
      } else {
        debugPrint('El correo aún no está verificado.');
      }
    } catch (e) {
      debugPrint('Error durante la verificación: $e');
      showCustomSnackBar(
          context, 'Error verificando el correo: $e', SnackBarType.error);
    } finally {
      // Asegurar que _isChecking siempre se actualice
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  // ignore: unused_element
  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        // Reenvía el enlace de verificación
        await user.sendEmailVerification();

        // Muestra un mensaje de éxito
        showCustomSnackBar(
            context,
            'Se ha enviado un nuevo enlace de verificación a tu correo.',
            SnackBarType.confirmation);
      }
    } catch (e) {
      // Manejo de errores
      showCustomSnackBar(
          context, 'Error al reenviar el correo: $e', SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verificar correo',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 25,
          ),
        ),
        leading: IconButton(
          icon: Image.asset('assets/images/exitDoor.png'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const FaIcon(
                FontAwesomeIcons.circleQuestion), // Ícono de FontAwesome
            onPressed: () {
              Funciones.mostrarModalDeAyuda(
                context: context,
                titulo: 'Ayuda',
                mensaje:
                    'Por favor, verifica tu correo electrónico y pulsa en el enlace proporcionado para confirmar tu cuenta. '
                    'Si no recibiste el correo, revisa tu carpeta de spam.',
              );
            },
          ),
        ],
        backgroundColor: Colors.green.shade200,
      ),
      body: BlurredBackground(
        child: Center(
          child: _isChecking
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Por favor verifica tu correo electrónico para continuar.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _checkEmailVerification,
                      child: const Text('He verificado mi correo'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
