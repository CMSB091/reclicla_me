import 'package:cloud_firestore/cloud_firestore.dart';

class Puntaje {
  final String email;
  final int puntos;
  final DateTime fecha;

  Puntaje({required this.email, required this.puntos, required this.fecha});

  factory Puntaje.fromDocument(DocumentSnapshot doc) {
    return Puntaje(
      email: doc['email'],
      puntos: doc['puntos'],
      fecha: (doc['fecha'] as Timestamp).toDate(),
    );
  }
}
