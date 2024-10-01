import 'package:flutter/material.dart';

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
        title: Text(title), // Título del artículo
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
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
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
