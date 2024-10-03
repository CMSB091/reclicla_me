import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ItemDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String contact;

  const ItemDetailScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context); // Acción de regresar
          },
        ),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Artwork', fontSize: 30),
        ), // Título del artículo
        backgroundColor: Colors.green.shade200, // Color de fondo similar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                imageUrl,
                height: 250,
                fit: BoxFit.contain, // Mostrar la imagen completa sin cortes
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Descripción: $description',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Contacto: $contact',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
