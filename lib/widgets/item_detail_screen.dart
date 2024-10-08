import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import 'package:intl/intl.dart'; // Para formatear el timestamp
import 'package:recila_me/clases/firestore_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String contact;
  final String userName; // Nombre del usuario que publicó el artículo
  final bool estado;
  final String email; // Estado de disponibilidad del artículo

  const ItemDetailScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.contact,
    required this.userName, // Recibir nombre de usuario
    required this.estado,
    required this.email, // Recibir estado del artículo
  });

  @override
  _ItemDetailScreenState createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  // Llamar a la función addComment desde el servicio
  void _handleAddComment() {
    final String newComment = _commentController.text.trim();

    if (newComment.isNotEmpty) {
      _firestoreService.addComment(
        imageUrl: widget.imageUrl,
        comentario: newComment,
        correo: widget.email, // Sustituir por el correo del usuario logueado
      );

      // Limpiar el input después de enviar el comentario
      _commentController.clear();
    }
  }

  // Función para formatear el Timestamp de Firestore a una fecha legible
  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

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
          widget.title,
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
                widget.imageUrl,
                height: 250,
                fit: BoxFit.contain, // Mostrar la imagen completa sin cortes
                errorBuilder: (context, error, stackTrace) {
                  return const Image(
                    image: AssetImage('assets/images/default_image.png'),
                    height: 250,
                    fit: BoxFit.contain, // Mostrar imagen por defecto
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Descripción: ${widget.description}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Contacto: ${widget.contact}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Publicado por: ${widget.userName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.estado ? 'No disponible' : 'Disponible',
              style: TextStyle(
                fontSize: 16,
                color: widget.estado ? Colors.red : Colors.green, // Color basado en el estado
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Título de sección para comentarios
            const Text(
              'Comentarios:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Input para agregar un comentario
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Agrega un comentario...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200, // Fondo del input
                    ),
                  ),
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.solidPaperPlane),
                  color: Colors.green.shade600,
                  onPressed: _handleAddComment, // Llamar a la función del servicio
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mostrar comentarios desde Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('comentarios')
                    .where('imageUrl', isEqualTo: widget.imageUrl) // Filtrar por imageUrl
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No hay comentarios disponibles.');
                  }
                  final comentarios = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: comentarios.length,
                    itemBuilder: (context, index) {
                      var comentario = comentarios[index];
                      Timestamp timestamp = comentario['timestamp'];

                      return FutureBuilder<String?>(
                        future: _firestoreService.getUserImageUrl(comentario['correo']),
                        builder: (context, snapshot) {
                          String? imageUrl = snapshot.data;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 238, 238, 238), // Tono más oscuro que el fondo
                              borderRadius: BorderRadius.circular(12), // Bordes redondeados
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                    ? NetworkImage(imageUrl)
                                    : const AssetImage('assets/images/perfil.png')
                                        as ImageProvider, // Imagen por defecto si no hay imageUrl
                                radius: 20,
                              ),
                              title: Text(comentario['comentario']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Publicado por: ${comentario['correo']}'),
                                  const SizedBox(height: 4),
                                  Text('Fecha: ${formatTimestamp(timestamp)}'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
