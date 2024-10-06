import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/item_detail_screen.dart';
import 'add_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userEmail;
  String? nombreUsuario;

  @override
  void initState() {
    super.initState();
    loadUserEmail(); // Cargar el email del usuario logueado
  }

  Future<void> loadUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    final nombre = await firestoreService.getUserName(user!.email.toString());
    setState(() {
      userEmail = user.email;
      nombreUsuario = nombre;
    });
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
        title: const Text(
          'Artículos en Donación',
          style: TextStyle(fontFamily: 'Artwork', fontSize: 20),
        ),
        backgroundColor: Colors.green.shade200,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddItemScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              bool isDonated = item['estado'] ?? false;
              String itemEmail = item['email'] ?? '';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Image.network(
                    item['imageUrl'], // Previsualización de la imagen
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  title: Text(
                      item['titulo'] ?? 'Sin título'), // Mostrar solo el título
                  trailing: userEmail == itemEmail
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(FontAwesomeIcons.pen),
                              onPressed: () {
                                // Lógica para editar el artículo
                              },
                            ),
                            IconButton(
                              icon: const Icon(FontAwesomeIcons.trash),
                              onPressed: () {
                                // Mostrar el diálogo de confirmación antes de eliminar
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title:
                                          const Text('Confirmar eliminación'),
                                      content: const Text(
                                          '¿Estás seguro de que deseas eliminar este post? Esta acción no se puede deshacer.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Cerrar diálogo sin eliminar
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Cerrar diálogo
                                            // Eliminar el post
                                            firestoreService.deletePost(
                                              context,
                                              item.id, // Pasar el ID del post
                                              imageUrl: item[
                                                  'imageUrl'], // Pasar la URL de la imagen si existe
                                            );
                                          },
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            // Mostrar el checkbox solo si el email coincide
                            Row(
                              children: [
                                Checkbox(
                                  value: isDonated,
                                  onChanged: (value) {
                                    _showConfirmationDialog(context, item.id, value!);
                                  },
                                ),
                                const Text("Concretado"),
                              ],
                            ),
                          ],
                        )
                      : null, // No mostrar nada si el email no coincide
                  onTap: () {
                    _navigateToItemDetail(
                      context,
                      item['imageUrl'],
                      item['titulo'] ?? 'Sin título',
                      item['description'] ?? 'Sin descripción',
                      item['contact'] ?? 'Sin contacto',
                      nombreUsuario!, // Nombre del usuario
                      item['estado'] ?? false, // Estado de donación
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Función para mostrar el modal de confirmación
  void _showConfirmationDialog(BuildContext context, String itemId, bool newState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar acción'),
          content: Text(newState
              ? '¿Estás seguro de que deseas marcar la publicación como concretada?'
              : '¿Estás seguro de que deseas marcar la publicación como no concretada?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Actualizar el estado en Firestore según el valor del checkbox
                firestoreService.updateDonationStatus(itemId, newState);
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  // Función para navegar a la página de detalles del artículo
  void _navigateToItemDetail(BuildContext context, String imageUrl,
      String title, String description, String contact, String username, bool estado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(
            imageUrl: imageUrl,
            title: title,
            description: description,
            contact: contact,
            userName: username,
            estado: estado),
      ),
    );
  }
}
