import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isDeleting = false;

  Future<User?> _getCurrentUser() async {
    return _auth.currentUser;
  }

  void _showDetailsModal(BuildContext context, String item, String material, String description, String date) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Objeto de ${item.toUpperCase()}',
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

  void _showDescriptionModal(BuildContext context, String item, String description) {
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
          content: const Text('¿Estás seguro de que deseas eliminar este elemento? Esta acción no se puede deshacer.'),
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
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
      mensaje:
          'Aquí puedes ver los tipos de objetos que fuiste escaneando.\n'
          'Puedes ver información adicional de cada item presionando el icono de "información."\n'
          'Puedes ver la recomendación guardada asociada a ese item presionando el icono de lista.\n'
          'Puedes eliminar el item presionando el icono del basurero.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
        title: const Text(
          'Objetos Reciclados',
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
                    child: Text('No se pudo cargar la información del usuario.'),
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
                    }
            
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No hay objetos registrados en el historial.',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Navegar a una pantalla de inicio o agregar reciclaje.
                            },
                            child: const Text('¡Agrega tu primer objeto reciclado!'),
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
                        final iconPath = Funciones.getMaterialIconPath(material);
            
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: Image.asset(
                              iconPath,
                              width: 50,
                              height: 50,
                            ),
                            title: Text(
                              detectedItem.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.infoCircle, color: Colors.blue),
                                  onPressed: () {
                                    _showDetailsModal(context, detectedItem, material, description, date);
                                  },
                                ),
                                if (description != 'Sin descripción disponible')
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.fileAlt, color: Colors.orange),
                                    onPressed: () {
                                      _showDescriptionModal(context, detectedItem, description);
                                    },
                                  ),
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
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
