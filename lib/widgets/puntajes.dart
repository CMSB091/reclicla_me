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
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Puntajes',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green.shade200,
      ),
      body: BlurredBackground(
        child: Column(
          children: [
            const SizedBox(height: 10), // Espacio entre AppBar y tabla
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('puntajes')
                    .orderBy('puntos', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error al cargar los puntajes.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No hay puntajes disponibles.'));
                  }

                  final puntajes = snapshot.data!.docs
                      .map((doc) => Puntaje.fromDocument(doc))
                      .toList();

                  return SingleChildScrollView(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal, // Scroll si es necesario
                        child: IntrinsicWidth(
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(10),
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
                              columnSpacing: 15,
                              border: TableBorder.all(
                                color: Colors.green.shade700,
                                width: 1,
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
                                    // Primera columna: Alineación a la izquierda
                                    DataCell(
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: FutureBuilder<Map<String, dynamic>?>(
                                          future: firestoreService
                                              .getUserData(puntaje.email),
                                          builder: (context, userSnapshot) {
                                            if (userSnapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Text('Cargando...');
                                            }
                                            if (userSnapshot.hasError) {
                                              return Text('Error: ${puntaje.email}');
                                            }

                                            final userData = userSnapshot.data;
                                            final userName =
                                                userData?['nombre'] ??
                                                    puntaje.email;

                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
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
                                                Flexible(
                                                  child: Text(
                                                    userName,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // Segunda columna: Puntaje centrado
                                    DataCell(
                                      Center(
                                        child: Text(
                                          puntaje.puntos.toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    // Tercera columna: Fecha centrada
                                    DataCell(
                                      Center(
                                        child: Text(
                                          DateFormat('dd/MM/yyyy')
                                              .format(puntaje.fecha),
                                        ),
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
            ),
          ],
        ),
      ),
    );
  }
}
