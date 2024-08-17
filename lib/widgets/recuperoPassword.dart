import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class recuperoPassword extends StatefulWidget {
  const recuperoPassword({super.key});

  @override
  _recuperoPasswordPage createState() => _recuperoPasswordPage();
}

class _recuperoPasswordPage extends State<recuperoPassword> {
  final _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarEmailRestablecimiento() async {
    final email = _emailController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese su email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se ha enviado un enlace de restablecimiento a tu correo')),
      );
      Navigator.pop(context); // Regresa a la página anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo Electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enviarEmailRestablecimiento,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Enviar Enlace de Restablecimiento'),
            ),
          ],
        ),
      ),
    );
  }
}
