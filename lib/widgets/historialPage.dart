import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialPage extends StatefulWidget {
  final String detectedItem;

  const HistorialPage({Key? key, required this.detectedItem}) : super(key: key);

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Guarda los datos en Firestore
  Future<void> _saveToFirestore() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        // Manejo si no hay un usuario logueado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontró usuario logueado.")),
        );
        return;
      }

      final email = user.email;
      final currentTime = DateTime.now();

      // Valida los campos antes de guardar
      if (_materialController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Todos los campos son obligatorios.")),
        );
        return;
      }

      // Guarda los datos en Firestore en la colección "historial"
      await FirebaseFirestore.instance.collection('historial').add({
        'item': widget.detectedItem,
        'material': _materialController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
        'email': email,
        'fecha': currentTime.toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Datos guardados exitosamente.")),
      );

      // Limpia los campos después de guardar
      setState(() {
        _materialController.clear();
        _descriptionController.clear();
      });
    } catch (e) {
      print("Error al guardar en Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }

  @override
  void dispose() {
    _materialController.dispose();
    _descriptionController.dispose();
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
              TextField(
                controller: _materialController,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
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
