import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/clases/puntaje.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';

class PuntajesScreen extends StatelessWidget {
  const PuntajesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Puntajes',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green.shade200,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('puntajes')
            .orderBy('puntos', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los puntajes.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay puntajes disponibles.'));
          }

          final puntajes = snapshot.data!.docs
              .map((doc) => Puntaje.fromDocument(doc))
              .toList();

          return BlurredBackground(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.green.shade400,
                        width: 2,
                      ),
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.lightGreenAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: DataTable(
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          width: 1,
                          color: Colors.green.shade700,
                          style: BorderStyle.solid,
                        ),
                        verticalInside: BorderSide(
                          width: 1,
                          color: Colors.green.shade700,
                          style: BorderStyle.solid,
                        ),
                      ),
                      columns: const [
                        DataColumn(label: Text('Usuario')),
                        DataColumn(label: Text('Puntaje')),
                        DataColumn(label: Text('Fecha')),
                      ],
                      rows: puntajes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final puntaje = entry.value;
            
                        return DataRow(
                          cells: [
                            DataCell(
                              FutureBuilder<Map<String, dynamic>?>(
                                future: firestoreService.getUserData(puntaje.email),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text('Cargando...');
                                  }
                                  if (userSnapshot.hasError) {
                                    return Text('Error: ${puntaje.email}');
                                  }
            
                                  final userData = userSnapshot.data;
                                  final userName = userData?['nombre'] ?? puntaje.email;
            
                                  return Row(
                                    children: [
                                      if (index < 3)
                                        FaIcon(
                                          FontAwesomeIcons.medal,
                                          color: index == 0
                                              ? Colors.amber
                                              : index == 1
                                                  ? Colors.grey
                                                  : Colors.brown,
                                          size: 16,
                                        ),
                                      const SizedBox(width: 5),
                                      Text(userName),
                                    ],
                                  );
                                },
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Text(
                                  puntaje.puntos.toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                DateFormat('dd/MM/yyyy').format(puntaje.fecha),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
