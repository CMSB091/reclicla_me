import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/object_detection_screen.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isDeleting = false;
  String? email;

  Future<User?> _getCurrentUser() async {
    return _auth.currentUser;
  }

  void _showDetailsModal(BuildContext context, String item, String material,
      String description, String date) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Objeto: ${item.toUpperCase()}',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha del reciclado: $date',
                  style: GoogleFonts.montserrat(fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showDescriptionModal(
      BuildContext context, String item, String description) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Cómo reciclar ${item.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Text(
              description,
              style: GoogleFonts.montserrat(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteItem(BuildContext context, DocumentReference itemRef) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text(
              '¿Estás seguro de que deseas eliminar este elemento? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isDeleting = true;
                });
                try {
                  await itemRef.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Elemento eliminado correctamente.'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al eliminar el elemento.'),
                    ),
                  );
                } finally {
                  setState(() {
                    _isDeleting = false;
                  });
                }
              },
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarAyuda(BuildContext context) {
    Funciones.mostrarModalDeAyuda(
      context: context,
      titulo: 'Ayuda',
      mensaje: 'Aquí puedes ver los tipos de objetos que fuiste escaneando.\n'
          'Puedes ver información adicional de cada item presionando el icono de "información."\n'
          'Puedes ver la recomendación guardada asociada a ese item presionando el icono "lista".\n'
          'Puedes eliminar el item presionando el icono del basurero.',
    );
  }

  Future<String?> fetchCurrentUserEmail() async {
    try {
      email = await Funciones().getCurrentUserEmail();
      if (email != null) {
        debugPrint('Email del usuario: $email');
      } else {
        debugPrint('No se pudo obtener el email del usuario.');
      }
      return email;
    } catch (e) {
      await Funciones.saveDebugInfo(
          'Error recuperando el email del usuario: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green.shade200,
            leading: IconButton(
              icon: const FaIcon(FontAwesomeIcons.house, color: Colors.black),
              onPressed: () {
                Funciones.navigateToHome(context);
              },
            ),
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit
                        .scaleDown, // Ajusta el tamaño del texto dinámicamente
                    child: Text(
                      'Objetos Reciclados',
                      style: TextStyle(
                        fontFamily: 'Artwork',
                        fontWeight: FontWeight.w400,
                        fontSize:
                            24, // Tamaño base que se ajustará automáticamente
                      ),
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true, // Asegura que el título se mantenga centrado
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.infoCircle),
                onPressed: () {
                  _mostrarAyuda(context);
                },
              ),
            ],
          ),
          body: BlurredBackground(
            child: FutureBuilder<User?>(
              future: _getCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child:
                        Text('No se pudo cargar la información del usuario.'),
                  );
                }

                final user = snapshot.data!;
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('historial')
                      .where('email', isEqualTo: user.email)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/animations/recycling3.json',
                            width: 400,
                            height: 400,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '¡Aún no has reciclado nada!',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Empieza hoy y ayuda a cuidar el planeta 🌍',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Recupera el email antes de navegar
                              String? email =
                                  await Funciones().getCurrentUserEmail();

                              if (email != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ObjectDetectionScreen(userEmail: email),
                                  ),
                                );
                              } else {
                                showCustomSnackBar(
                                    context,
                                    'No se pudo obtener el email del usuario.',
                                    SnackBarType.error);
                              }
                            },
                            icon: const FaIcon(FontAwesomeIcons.recycle),
                            label: const Text('¡Empieza a reciclar ahora!'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade400,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 20.0),
                              textStyle: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final items = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final data = item.data() as Map<String, dynamic>;

                        final detectedItem = data['material'] ?? 'Desconocido';
                        final description = data.containsKey('descripcion')
                            ? data['descripcion']
                            : 'Sin descripción';
                        final material = data['item'] ?? 'Sin material';
                        final date = data['fecha'] ?? 'Sin fecha';
                        final iconPath =
                            Funciones.getMaterialIconPath(material);

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: Image.asset(
                              iconPath,
                              width: 50,
                              height: 50,
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit
                                        .scaleDown, // Ajusta dinámicamente el tamaño
                                    child: Text(
                                      detectedItem.toUpperCase(),
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            16, // Tamaño base, se ajustará dinámicamente
                                      ),
                                      overflow: TextOverflow
                                          .ellipsis, // Evita desbordamientos
                                      softWrap:
                                          true, // Permite que el texto se divida en varias líneas si es necesario
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const FaIcon(
                                      FontAwesomeIcons.infoCircle,
                                      color: Colors.blue),
                                  onPressed: () {
                                    _showDetailsModal(context, detectedItem,
                                        material, description, date);
                                  },
                                ),
                                if (description != 'Sin descripción disponible')
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.fileAlt,
                                        color: Colors.orange),
                                    onPressed: () {
                                      _showDescriptionModal(
                                          context, detectedItem, description);
                                    },
                                  ),
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.trash,
                                      color: Colors.red),
                                  onPressed: () {
                                    _confirmDeleteItem(context, item.reference);
                                  },
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
          ),
        ),
        if (_isDeleting)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
