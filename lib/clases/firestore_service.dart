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
}
