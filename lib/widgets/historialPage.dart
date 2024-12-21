import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';

class HistorialPage extends StatefulWidget {
  final String detectedItem;
  final String initialDescription;

  const HistorialPage({super.key, required this.detectedItem, required this.initialDescription});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final TextEditingController _materialController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Configura los campos iniciales
    _materialController.text = ''; // Inicializa vacío
  }

  Future<void> _saveToFirestore() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        // Manejo si no hay un usuario logueado
        showCustomSnackBar(
            context, 'No se encontró usuario logueado.', SnackBarType.error,
            durationInMilliseconds: 2000);
        return;
      }

      final email = user.email;
      final currentTime = DateTime.now();

      // Valida los campos antes de guardar
      if (_materialController.text.trim().isEmpty) {
        showCustomSnackBar(
            context, 'Todos los campos son obligatorios.', SnackBarType.error,
            durationInMilliseconds: 3000);
        return;
      }

      await FirebaseFirestore.instance.collection('historial').add({
        'item': widget.detectedItem, // Objeto escaneado
        'material': _materialController.text.trim(), // Material cargado por el usuario
        'descripcion': widget.initialDescription.trim(), // Recomendación de ChatGPT
        'email': email, // Email del usuario logueado
        'fecha': currentTime.toIso8601String(), // Fecha actual
      });
      showCustomSnackBar(
          context, 'Datos guardados exitosamente.', SnackBarType.confirmation,
          durationInMilliseconds: 3000);

      // Limpia los campos después de guardar
      setState(() {
        _materialController.clear();
      });
    } catch (e) {
      showCustomSnackBar(
            context, 'Error al guardar: $e', SnackBarType.error,
            durationInMilliseconds: 3000);
    }
  }

  @override
  void dispose() {
    _materialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Objetos'),
        centerTitle: true,
        backgroundColor: Colors.green.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo para el ítem detectado (Texto no editable)
              Text(
                'Ítem Detectado:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.detectedItem,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 20),
              // Campo editable para Material
              TextField(
                controller: _materialController,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // Campo no editable para la Descripción
              Text(
                'Descripción:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.initialDescription,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              // Botón de Guardar
              Center(
                child: ElevatedButton(
                  onPressed: _saveToFirestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
