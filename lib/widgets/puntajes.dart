// Pantalla para mostrar los puntajes almacenados
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PuntajesScreen extends StatelessWidget {
  const PuntajesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntajes',style: TextStyle(
          fontFamily: 'Artwork',
          fontSize: 22,
        ),),
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final puntajes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: puntajes.length,
            itemBuilder: (context, index) {
              final puntaje = puntajes[index];
              return ListTile(
                title: Text('Usuario: ${puntaje['email']}'),
                subtitle: Text('Puntaje: ${puntaje['puntos']}'),
                trailing: Text(
                    'Fecha: ${puntaje['fecha'].toDate().toString().split(' ')[0]}'),
              );
            },
          );
        },
      ),
    );
  }
}