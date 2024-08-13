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

  Future<String> getUserName(String correo) async {
  try {
    // Obtén el documento del usuario basado en el correo electrónico
    QuerySnapshot query = await _db.collection('usuario').where('correo', isEqualTo: correo).limit(1).get();
    
    print('Query snapshot count: ${query.docs.length}'); // Depuración

    if (query.docs.isNotEmpty) {
      // Obtén el ID del primer documento encontrado
      String docId = query.docs.first.id;
      print('Document ID: $docId'); // Depuración

      // Usa el ID para obtener el documento específico
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuario')  // Asegúrate de usar la misma colección que antes
          .doc(docId)
          .get();

      print('Document exists: ${doc.exists}'); // Depuración

      if (doc.exists) {
        // Obtén los datos del documento
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        
        print('Document data: $data'); // Depuración

        if (data != null && data.containsKey('nombre')) {
          String firstName = data['nombre'] ?? correo;
          print('Document firstName: $firstName'); // Depuración
          return firstName;
        } else {
          print('Field "nombre" not found in the document.');
          return correo; // Valor por defecto si el campo no está presente
        }
      } else {
        print('Document does not exist.');
        return correo; // Valor por defecto si el documento no existe
      }
    } else {
      print('No document found with the provided email.');
      return correo; // Valor por defecto si no se encuentra el documento
    }
  } catch (e) {
    print('Error retrieving user data: $e');
    return correo;
  }
}

}


