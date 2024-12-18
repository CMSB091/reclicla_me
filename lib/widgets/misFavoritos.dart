import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';

class MisFavoritos extends StatefulWidget {
  final String userEmail;

  const MisFavoritos({super.key, required this.userEmail});

  @override
  _MisFavoritosState createState() => _MisFavoritosState();
}

class _MisFavoritosState extends State<MisFavoritos> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Favoritos',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.green.shade200,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.house, color: Colors.black),
          onPressed: () {
            Funciones.navigateToHome(context);
          },
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.infoCircle),
            onPressed: () {
              Funciones.mostrarModalDeAyuda(
                context: context,
                titulo: 'Ayuda',
                mensaje:
                    'Desliza la pantalla a los costados para navegar entre los favoritos.',
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserRecommendations(widget.userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error en el flujo: ${snapshot.error}');
            return const Center(
              child: Text('Ocurrió un error al cargar las recomendaciones.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint(
                'No se encontraron recomendaciones para: ${widget.userEmail}');
            return const Center(
              child: Text('No tienes recomendaciones aún.'),
            );
          }

          final recommendations = snapshot.data!.docs;

          return PageView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final data =
                  recommendations[index].data() as Map<String, dynamic>;
              final recommendation = data['recommendation'] ?? '';
              final docId = recommendations[index].id;

              return Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          recommendation,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade200,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 20),
                                      Text('Descargando PDF...'),
                                    ],
                                  ),
                                );
                              },
                            );

                            try {
                              await Funciones.descargarPdf(
                                titulo: 'Favorito ${index + 1}',
                                contenido: recommendation,
                                context: context,
                              );

                              if (mounted) {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                                showCustomSnackBar(
                                    context,
                                    'PDF descargado con éxito.',
                                    SnackBarType.confirmation);
                              }
                            } catch (e) {
                              debugPrint('Error al descargar PDF: $e');

                              if (mounted) {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                                showCustomSnackBar(
                                    context,
                                    'Error al descargar el PDF.',
                                    SnackBarType.error);
                              }
                            }
                          },
                          icon: const FaIcon(FontAwesomeIcons.filePdf),
                          label: const Text('Descargar PDF'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirmar eliminación'),
                                  content: const Text(
                                      '¿Estás seguro de que deseas eliminar este favorito?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              try {
                                debugPrint(
                                    'Intentando eliminar documento con ID: $docId');
                                await _firestoreService
                                    .deleteUserRecommendation(
                                        widget.userEmail, docId);
                                debugPrint(
                                    'Documento eliminado correctamente por ID.');
                                setState(() {}); // Refresca la interfaz
                                showCustomSnackBar(
                                    context,
                                    'Favorito eliminado.',
                                    SnackBarType.confirmation);
                              } catch (e) {
                                debugPrint('Error al eliminar favorito: $e');
                                showCustomSnackBar(
                                    context,
                                    'Error al eliminar el favorito.',
                                    SnackBarType.error);
                              }
                            }
                          },
                          icon: const FaIcon(FontAwesomeIcons.trash),
                          label: const Text('Eliminar'),
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
    );
  }
}
