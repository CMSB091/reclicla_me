import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';
import 'addItemScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userEmail;
  String? nombreUsuario;
  bool _isLoading = false;
  final Funciones _funciones = Funciones();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail != null) {
      loadUserEmail(userEmail!);
    }
  }

  Future<void> loadUserEmail(String email) async {
    print('email $email');
    final nombre = await firestoreService.getUserName(email);
    setState(() {
      print('nombre $nombre');
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
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Artículos en Donación',
          style: TextStyle(fontFamily: 'Artwork', fontSize: 22),
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
      body: Builder(
        builder: (BuildContext scaffoldContext) {
          return BlurredBackground(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Buscar Artículo',
                      prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('items')
                        .orderBy('idpub', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final items = snapshot.data!.docs;
                      final filteredItems = items.where((item) {
                        String titulo =
                            item['titulo']?.toString().toLowerCase() ?? '';
                        return titulo.contains(_searchQuery);
                      }).toList();

                      if (filteredItems.isEmpty) {
                        return const Center(
                            child: Text('No se encontraron resultados.'));
                      }

                      return ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          var item = filteredItems[index];
                          String itemId = item.id;
                          String idpub = item['idpub'].toString();
                          bool isDonated =
                              (item['estado'] is bool) ? item['estado'] : false;
                          String itemEmail = item['email'] ?? '';

                          return Card(
                            color: Colors.grey.withOpacity(0.1),
                            margin: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item['titulo'] ?? 'Sin título',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'ID: $idpub',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            _isLoading = true;
                                          });

                                          try {
                                            String pais = await firestoreService
                                                .getPaisFromUsuario(itemEmail);
                                            await loadUserEmail(item['email']);

                                            if (nombreUsuario != null &&
                                                userEmail != null) {
                                              _funciones.navigateToItemDetail(
                                                context,
                                                item['imageUrl'],
                                                item['titulo'] ?? 'Sin título',
                                                item['description'] ??
                                                    'Sin descripción',
                                                item['contact'] ??
                                                    'Sin contacto',
                                                nombreUsuario!,
                                                item['estado'] ?? false,
                                                userEmail!,
                                                pais,
                                                item['idpub'].toString(),
                                              );
                                            } else {
                                              showCustomSnackBar(
                                                  scaffoldContext,
                                                  'Error al recuperar los datos del usuario',
                                                  SnackBarType.error);
                                            }
                                          } finally {
                                            setState(() {
                                              _isLoading = false;
                                            });
                                          }
                                        },
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: item['imageUrl'],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                              imageBuilder: (context, imageProvider) => Image(
                                                image: imageProvider,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                              // Reduzcamos la calidad con un tamaño de miniatura
                                              memCacheWidth: 150, // Puedes ajustar este valor
                                              memCacheHeight: 150, // Puedes ajustar este valor
                                            ),
                                            if (_isLoading)
                                              const CircularProgressIndicator(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (userEmail != itemEmail)
                                      Expanded(
                                        child: Text(
                                          isDonated
                                              ? "Disponible"
                                              : "No Disponible",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDonated
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  FontAwesomeIcons.pen,
                                                  color: Colors.black),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AddItemScreen(
                                                      itemId: itemId,
                                                      titulo: item['titulo'],
                                                      description:
                                                          item['description'],
                                                      contact: item['contact'],
                                                      imageUrl:
                                                          item['imageUrl'],
                                                      isEdit: true,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  FontAwesomeIcons.trash),
                                              color: Colors.black,
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'Confirmar eliminación'),
                                                      content: const Text(
                                                          '¿Estás seguro de que deseas eliminar este post? Esta acción no se puede deshacer.'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                              'Cancelar'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () async {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();

                                                            setState(() {
                                                              _isLoading = true;
                                                            });

                                                            try {
                                                              await firestoreService
                                                                  .deletePost(
                                                                      scaffoldContext,
                                                                      item.id,
                                                                      imageUrl:
                                                                          item[ 'imageUrl']);
                                                              showCustomSnackBar(
                                                                scaffoldContext,
                                                                'Publicación eliminada correctamente',
                                                                SnackBarType.confirmation,
                                                              );
                                                            } catch (e) {
                                                              showCustomSnackBar(
                                                                scaffoldContext,
                                                                'Error al eliminar la publicación',
                                                                SnackBarType.error,
                                                              );
                                                              debugPrint('Error al eliminar la publicación: $e');
                                                            } finally {
                                                              setState(() {
                                                                _isLoading = false;
                                                              });
                                                            }
                                                          },
                                                          child: const Text('Eliminar'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            Row(
                                              children: [
                                                Checkbox(
                                                  activeColor: Colors.green,
                                                  value: isDonated,
                                                  onChanged: (value) {
                                                    _showConfirmationDialog(
                                                        scaffoldContext,
                                                        itemId,
                                                        value!);
                                                  },
                                                ),
                                                const Text(
                                                  "Concretado",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, String itemId, bool newState) {
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
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                firestoreService.updateDonationStatus(itemId, newState);
                Navigator.of(context).pop();
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }
}
