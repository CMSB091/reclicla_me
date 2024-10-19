import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
// Para formatear el timestamp
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/clases/utilities.dart';
// Importar permisos

class ItemDetailScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String contact;
  final String userName; // Nombre del usuario que publicó el artículo
  final bool estado;
  final String email;
  final String pais; // Estado de disponibilidad del artículo

  const ItemDetailScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.contact,
    required this.userName, // Recibir nombre de usuario
    required this.estado,
    required this.email,
    required this.pais,
  });

  @override
  _ItemDetailScreenState createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final Utilidades utilidades = Utilidades();
  final Funciones funciones = Funciones();

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
  // Función para mostrar el modal de confirmación
  void _showConfirmationDialog(BuildContext context, String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
              '¿Estás seguro de que deseas eliminar este comentario?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _firestoreService.deleteComment(commentId); // Eliminar el comentario
                Navigator.of(context)
                    .pop(); // Cerrar el diálogo después de eliminar
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser; // Obtener el usuario logueado
    final String? loggedInEmail = user?.email; // Email del usuario logueado

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
      // Ajustar automáticamente cuando aparece el teclado
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        // Permitir desplazamiento cuando el teclado está visible
        child: Padding(
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
              // Actualizamos aquí la sección "Descripción"
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          'Descripción: ', // El texto "Descripción:" en negrita
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            Colors.black, // Asegurarse que sea de color negro
                      ),
                    ),
                    TextSpan(
                      text:
                          widget.description, // El contenido de la descripción
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                        color:
                            Colors.black, // Asegurarse que sea de color negro
                      ),
                    ),
                  ],
                ),
              ),
              // Sección de contacto con ícono de WhatsApp en la misma línea
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text:
                                'Contacto: ', // El texto "Contacto" en negrita
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: widget.contact, // El contacto
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp),
                    color: Colors.green,
                    onPressed: () {
                      utilidades.checkIfAppIsInstalled(); // eliminar al finalizar
                      utilidades.listInstalledApps(); // eliminar al finalizar
                      funciones.launchWhatsApp(
                          widget.contact, widget.pais,context); // Abrir WhatsApp
                    },
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          'Publicado por: ', // El texto "Descripción:" en negrita
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            Colors.black, // Asegurarse que sea de color negro
                      ),
                    ),
                    TextSpan(
                      text: widget.userName, // El contenido del usuario
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                        color:
                            Colors.black, // Asegurarse que sea de color negro
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.estado ? 'No disponible' : 'Disponible',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.estado
                      ? Colors.red
                      : Colors.green, // Color basado en el estado
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Título de sección para comentarios
              const Text(
                'Comentarios:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Input para agregar un comentario
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLength: 250, // Restricción de 250 caracteres
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
                    onPressed:
                        _handleAddComment, // Llamar a la función del servicio
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Mostrar comentarios desde Firestore
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('comentarios')
                    .where('imageUrl', isEqualTo: widget.imageUrl)
                    .orderBy('timestamp',
                        descending: true) // Filtrar por imageUrl
                    .snapshots(), // Se agrega un indice en firestore
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No hay comentarios disponibles.');
                  }
                  final comentarios = snapshot.data!.docs;

                  return ListView.builder(
                    physics:
                        const NeverScrollableScrollPhysics(), // Desactivar el scroll interno
                    shrinkWrap: true, // Ajustar el ListView a su contenido
                    itemCount: comentarios.length,
                    itemBuilder: (context, index) {
                      var comentario = comentarios[index];
                      Timestamp timestamp = comentario['timestamp'];
                      String commentId = comentario.id;

                      return FutureBuilder<String?>(
                        future: _firestoreService
                            .getUserImageUrl(comentario['correo']),
                        builder: (context, snapshot) {
                          String? imageUrl = snapshot.data;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 238, 238,
                                  238), // Tono más oscuro que el fondo
                              borderRadius: BorderRadius.circular(
                                  12), // Bordes redondeados
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: imageUrl != null &&
                                        imageUrl.isNotEmpty
                                    ? NetworkImage(imageUrl)
                                    : const AssetImage(
                                            'assets/images/perfil.png')
                                        as ImageProvider, // Imagen por defecto si no hay imageUrl
                                radius: 20,
                              ),
                              title: Text(comentario['comentario']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Publicado por: ${comentario['correo']}'),
                                  const SizedBox(height: 4),
                                  Text('Fecha: ${funciones.formatTimestamp(timestamp)}'),
                                  const SizedBox(height: 4),
                                  // Mostrar "Eliminar" solo si el usuario logueado es el autor del comentario
                                  if (loggedInEmail == comentario['correo'])
                                    GestureDetector(
                                      onTap: () {
                                        _showConfirmationDialog(
                                            context, commentId);
                                      },
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(
                                          color: Colors.red,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}
