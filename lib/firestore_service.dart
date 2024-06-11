import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> authenticateUser(String correo, String contrasena) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                    .collection('usuario')
                    .where('correo', isEqualTo: correo)
                    .where('contrasena', isEqualTo: contrasena) 
                    .get();

                if (querySnapshot.docs.isEmpty) {
                  return false;
                } else {
                  final userDoc = querySnapshot.docs.first;
                  final userData = userDoc.data() as Map<String, dynamic>;
                  return true;
                  }
    } catch (e) {
        print('Error autenticando usuario: $e');
      return false;
    }
  }
}
