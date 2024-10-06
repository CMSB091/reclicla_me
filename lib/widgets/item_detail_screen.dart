import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ItemDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String contact;
  final String userName; // Nombre del usuario que publicó el artículo
  final bool estado; // Estado de disponibilidad del artículo

  const ItemDetailScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.contact,
    required this.userName, // Recibir nombre de usuario
    required this.estado, // Recibir estado del artículo
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
            const SizedBox(height: 10),
            Text(
              'Publicado por: $userName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              estado ? 'No disponible' : 'Disponible',
              style: TextStyle(
                fontSize: 16,
                color: estado ? Colors.red : Colors.green, // Color basado en el estado
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
