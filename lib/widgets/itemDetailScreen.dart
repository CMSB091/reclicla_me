import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/clases/utilities.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';

class ItemDetailScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String contact;
  final String userName;
  final bool estado;
  final String email;
  final String pais;
  final String idpub;

  const ItemDetailScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.contact,
    required this.userName,
    required this.estado,
    required this.email,
    required this.pais,
    required this.idpub,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ItemDetailScreenState createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final Utilidades utilidades = Utilidades();
  final Funciones funciones = Funciones();

  void _handleAddComment() {
    final String newComment = _commentController.text.trim();
    if (newComment.isNotEmpty) {
      _firestoreService.addComment(
        imageUrl: widget.imageUrl,
        comentario: newComment,
        correo: widget.email,
      );
      _commentController.clear();
    } else {
      showCustomSnackBar(
          context, 'Debe ingresar un comentario!!', SnackBarType.error);
    }
  }

  void _showConfirmationDialog(BuildContext context, String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content:
              const Text('¿Estás seguro de que deseas eliminar este comentario?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _firestoreService.deleteComment(commentId);
                Navigator.of(context).pop();
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
    final User? user = FirebaseAuth.instance.currentUser;
    final String? loggedInEmail = user?.email;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.title,
          style: const TextStyle(fontFamily: 'Artwork', fontSize: 22),
        ),
        backgroundColor: Colors.green.shade200,
      ),
      resizeToAvoidBottomInset: true,
      body: BlurredBackground(
        opacity: 0.1,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(
                    widget.imageUrl,
                    height: 250,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Image(
                        image: AssetImage('assets/images/default_image.png'),
                        height: 250,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Descripción: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: widget.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Contacto: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: widget.contact,
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
                    if (widget.contact.isNotEmpty)
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.whatsapp),
                        color: const Color.fromARGB(255, 6, 128, 10),
                        onPressed: () {
                          funciones.launchWhatsApp(
                            widget.contact,
                            widget.pais,
                            context,
                            widget.idpub,
                            widget.title,
                            widget.imageUrl,
                          );
                        },
                      ),
                  ],
                ),
                if (widget.contact.isEmpty) const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Publicado por: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: widget.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.estado ? 'Disponible' : 'No Disponible',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.estado
                        ? const Color.fromARGB(255, 6, 128, 10)
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Comentarios:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        maxLength: 250,
                        decoration: InputDecoration(
                          hintText: 'Agrega un comentario...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        child: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.solidPaperPlane),
                          color: Colors.green.shade600,
                          onPressed: _handleAddComment,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('comentarios')
                      .where('imageUrl', isEqualTo: widget.imageUrl)
                      .orderBy('timestamp', descending: true)
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
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
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
                              margin:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 238, 238, 238),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: imageUrl != null &&
                                          imageUrl.isNotEmpty
                                      ? NetworkImage(imageUrl)
                                      : const AssetImage(
                                              'assets/images/perfil.png')
                                          as ImageProvider,
                                  radius: 20,
                                ),
                                title: Text(comentario['comentario']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Publicado por: ${comentario['correo']}'),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Fecha: ${funciones.formatTimestamp(timestamp)}'),
                                    const SizedBox(height: 4),
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
                                            decoration:
                                                TextDecoration.underline,
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
      ),
    );
  }
}
