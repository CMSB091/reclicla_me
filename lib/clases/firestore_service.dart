import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> authenticateUser(String correo, String contrasena) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('usuario')
          .where('correo', isEqualTo: correo)
          .where('contrasena', isEqualTo: contrasena)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  // Método para crear un nuevo usuario
  Future<bool> createUser(String correo, String contrasena) async {
    try {
      await _db.collection('usuario').add({
        'correo': correo,
        'contrasena': contrasena,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUser(String nombre, String apellido, int edad, String direccion,String ciudad, String pais, String telefono, String correo) async {
    try {
      // Consultar el documento basado en el correo electrónico
      QuerySnapshot querySnapshot = await _db.collection('usuario').where('correo', isEqualTo: correo).limit(1).get();
      String docId = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : '';
      if (docId.isNotEmpty) {
        // Actualizar el documento con el ID obtenido
        await _db.collection('usuario').doc(docId).update({
          'nombre': nombre,
          'apellido': apellido,
          'edad': edad,
          'direccion': direccion,
          'ciudad': ciudad,
          'pais': pais,
          'telefono': telefono,
        });
        return true;
      } else {
        print('No se encontró ningún usuario con el correo electrónico proporcionado');
        return false;
      }
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    final snapshot = await _db.collection('usuario').where('correo', isEqualTo: email).get();
    return snapshot.docs.isNotEmpty;
  }
}


