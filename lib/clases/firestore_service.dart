import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:intl/intl.dart'; // Para formatear las fechas.

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
      Funciones.SeqLog('error', 'Se produjo un error en la autenticación $e');
      return false;
    }
  }

  // Método para crear un nuevo usuario
  Future<bool> createUser(String email) async {
    try {
      await _db.collection('usuario').doc(email).set({
        'correo': email,
      });
      return true;
    } catch (e) {
      await Funciones.SeqLog('error', 'Error creating user: $e');
      return false;
    }
  }

  // Método para actualizar los datos del usuario
  Future<bool> updateUser(
      String nombre,
      String apellido,
      int edad,
      String direccion,
      String ciudad,
      String pais,
      String telefono,
      String correo) async {
    try {
      // Consulta el documento basado en el correo electrónico
      QuerySnapshot querySnapshot = await _db
          .collection('usuario')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();
      String docId =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : '';
      if (docId.isNotEmpty) {
        // Actualiza el documento con el ID obtenido
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
        await Funciones.SeqLog('information',
            'No se encontró ningún usuario con el correo electrónico proporcionado');
        return false;
      }
    } catch (e) {
      await Funciones.SeqLog('error', 'Error updating user: $e');
      return false;
    }
  }

  // Método que valida si existe un email ya registrado en la base de datos
  Future<bool> checkEmailExists(String email) async {
    final snapshot =
        await _db.collection('usuario').where('correo', isEqualTo: email).get();
    return snapshot.docs.isNotEmpty;
  }

  // Método que recupera el nombre del usuario
  Future<String> getUserName(String correo) async {
    try {
      QuerySnapshot query = await _db
          .collection('usuario')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();

      await Funciones.SeqLog(
          'debug', 'Query snapshot count: ${query.docs.length}');

      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        await Funciones.SeqLog('debug', 'Document ID: $docId');

        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuario')
            .doc(docId)
            .get();

        await Funciones.SeqLog('debug', 'Document exists: ${doc.exists}');

        if (doc.exists) {
          // Valida que se haya recuperado los datos
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          await Funciones.SeqLog('debug', 'Document data: $data');

          if (data != null && data.containsKey('nombre')) {
            String firstName = data['nombre'] ?? correo;
            await Funciones.SeqLog('debug', 'Document firstName: $firstName');
            return firstName;
          } else {
            await Funciones.SeqLog(
                'information', 'Field "nombre" not found in the document.');
            return correo; // Valor por defecto
          }
        } else {
          await Funciones.SeqLog('information', 'Document does not exist.');
          return correo; // Valor por defecto
        }
      } else {
        await Funciones.SeqLog(
            'information', 'No document found with the provided email.');
        return correo; // Valor por defecto
      }
    } catch (e) {
      await Funciones.SeqLog('error', 'Error retrieving user data: $e');
      return correo;
    }
  }

  //Método que recupera todos los datos del usuario
  Future<Map<String, dynamic>?> getUserData(String correo) async {
    await Funciones.SeqLog('debug', 'EMAIL INGREASADO: $correo}');
    try {
      QuerySnapshot query = await _db
          .collection('usuario')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();

      await Funciones.SeqLog(
          'debug', 'Query snapshot count: ${query.docs.length}');

      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        await Funciones.SeqLog('debug', 'Document ID: $docId');

        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuario')
            .doc(docId)
            .get();

        await Funciones.SeqLog('debug', 'Document exists: ${doc.exists}');

        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          await Funciones.SeqLog('debug', 'Document data: $data');

          return data; // Retorna los datos del usuario
        } else {
          await Funciones.SeqLog('information', 'Document does not exist.');
          return null; // Retorna null si el documento no existe
        }
      } else {
        await Funciones.SeqLog(
            'information', 'No document found with the provided email.');
        return null; // Retorna null si no se encuentra el documento
      }
    } catch (e) {
      await Funciones.SeqLog('error', 'Error retrieving user data: $e');
      return null;
    }
  }

  //Método para eliminar usuario
  Future<bool> deleteUser(String correo) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('usuario')
          .where('correo', isEqualTo: correo)
          .get();
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
        return true;
      } else {
        return false; // No se encontró el usuario con el correo especificado
      }
    } catch (e) {
      await Funciones.SeqLog('error', 'Error al eliminar el usuario: $e');
      return false;
    }
  }

  // Metodo para obtener los paises de la base de datos
  Future<List<String>> getPaises() async {
    try {
      final snapshot = await _db.collection('paises').get();
      return snapshot.docs.map((doc) => doc['nombre'] as String).toList();
    } catch (e) {
      await Funciones.SeqLog('error', 'Error al obtener países: $e');
      return [];
    }
  }

  // Metodo para obtener las ciudades de la base de datos
  Future<List<String>> getCiudadesPorPais(String paisId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ciudades')
          .where('pais', isEqualTo: paisId)
          .get();

      List<String> ciudades = snapshot.docs.map((doc) {
        return doc['nombre'] as String;
      }).toList();

      return ciudades;
    } catch (e) {
      await Funciones.SeqLog('error', 'Error al cargar las ciudades: $e');
      throw Exception('Error al cargar las ciudades: $e');
    }
  }

  // Metodo para guardar las recomendaciones obtenidas de la consulta al chatBot
  void saveInteractionToFirestore(
      String prompt, String response, String userMail) {
    FirebaseFirestore.instance.collection('chat_interactions').add({
      'userPrompt': prompt,
      'chatResponse': response,
      'timestamp': FieldValue.serverTimestamp(),
      'email': userMail
    });
  }

  // Metodo para recuperar el email del usuario
  Future<String?> loadUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  // Metodo para recuperar el historial de consultas al chatBot
  Future<List<Map<String, dynamic>>> fetchChatHistoryByEmail(
      String userEmail) async {
    try {
      // Se obtiene los datos filtrados por el correo electrónico
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('chat_interactions')
          .where('email', isEqualTo: userEmail)
          .get();

      // Se retorna los datos como una lista
      return snapshot.docs.map((doc) {
        // Se convierte la fecha a un formato legible
        String formattedDate = '';
        if (doc['timestamp'] != null) {
          formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(doc['timestamp'].toDate());
        }

        return {
          'id': doc.id,
          'timestamp': formattedDate,
          'userPrompt': doc['userPrompt'] ?? '',
          'chatResponse': doc['chatResponse'] ?? '',
        };
      }).toList();
    } catch (e) {
      Funciones.SeqLog('error', 'Error al recuperar el historial de chat: $e');
      return [];
    }
  }

  // Metodo que recupera las recomendaciones de la base de datos para entrenar el modelo
  Future<List<Map<String, String>>> fetchInteractionsFromFirestore() async {
    List<Map<String, String>> interactions = [];

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('chat_interactions')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      for (var doc in snapshot.docs) {
        // Maneja posibles valores nulos para 'userPrompt' y 'chatResponse'
        String userPrompt = doc['userPrompt'] ?? 'No user prompt available';
        String chatResponse = doc['chatResponse'] ?? 'No response available';

        interactions.add({
          'userPrompt': userPrompt,
          'chatResponse': chatResponse,
        });
      }
    } catch (e) {
      await Funciones.SeqLog(
          'error', 'Error fetching interactions from Firestore: $e');
    }

    return interactions;
  }

  // Metodo que elimina los chats guardados del historial de chats
  Future<void> deleteChatById(String? chatId) async {
    // Verificar si chatId es null o vacío
    if (chatId == null || chatId.isEmpty) {
      Funciones.SeqLog('warning', 'ID de chat no válido: null o vacío.');
      return;
    }

    try {
      DocumentSnapshot chatDoc = await FirebaseFirestore.instance
          .collection('chat_interactions')
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        // Si el documento existe, proceder a eliminarlo
        await FirebaseFirestore.instance
            .collection('chat_interactions')
            .doc(chatId)
            .delete();
        Funciones.SeqLog(
            'information', 'Chat con ID $chatId eliminado correctamente.');
      } else {
        // Si el documento no existe
        Funciones.SeqLog('warning',
            'No se encontró un chat con el ID $chatId para eliminar.');
      }
    } catch (e) {
      Funciones.SeqLog('error', 'Error al eliminar el chat: $e');
    }
  }

  Future<String?> getUserProfileImage(String email) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;
        // Ruta donde se almacena la imagen de perfil en Firebase Storage
        Reference storageReference =
            FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');

        // Obtener la URL de descarga de la imagen
        String imageUrl = await storageReference.getDownloadURL();
        return imageUrl; // Devuelve la URL de la imagen
      } else {
        throw ('No se ha autenticado ningún usuario');
      }
    } catch (e) {
      print('Error al recuperar la imagen de perfil: $e');
      return null; // Devuelve null si no hay imagen o si ocurre un error
    }
  }

  Future<void> updateUserProfileImage(String correo, String downloadUrl) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'No hay un usuario autenticado';
      }

      // Pick an image from the user's device
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        throw 'No se seleccionó ninguna imagen';
      }

      File imageFile = File(pickedFile.path);

      // Upload the image to Firebase Storage
      String uid = user.uid;
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL of the uploaded image
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update the user's profile with the new image URL (if needed)
      // Example: Save to Firestore or update Firebase Auth profile
      print('Nueva URL de la imagen: $downloadUrl');

      // Return success
      print('Imagen de perfil actualizada correctamente');
    } catch (e) {
      print('Error al actualizar la imagen de perfil: $e');
    }
  }

  // Función para verificar conectividad a Internet
  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  // Función para subir la imagen a Firebase Storage y guardar la URL en Firestore
  Future<void> uploadImageAndSaveToFirestore(
      {required File imageFile,
      required String description,
      required String contact,
      required GlobalKey<ScaffoldState> scaffoldKey, // Para mostrar el SnackBar
      required String email,
      required String titulo,
      required bool estado}) async {
    // Verificar conexión a Internet antes de subir la imagen
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      showSnackBar(scaffoldKey, 'No tienes conexión a Internet.');
      return;
    }

    try {
      // Verificar si el archivo existe
      if (!await imageFile.exists()) {
        showSnackBar(
            scaffoldKey, 'El archivo no existe en la ruta especificada.');
        return;
      }

      print('Subiendo imagen, por favor espera...');

      // Generar una referencia única para la imagen en Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Subir la imagen a Firebase Storage
      UploadTask uploadTask = ref.putFile(imageFile);

      // Monitorear el progreso de la subida
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
            'Progreso: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
      }, onError: (e) {
        showSnackBar(scaffoldKey, 'Error durante la subida de la imagen.');
        print('Error durante la subida: $e');
      });

      // Esperar hasta que la subida se complete
      TaskSnapshot taskSnapshot = await uploadTask;
      if (taskSnapshot.state == TaskState.success) {
        // Obtener la URL de descarga solo si la subida fue exitosa
        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen subida: $imageUrl');

        // Guardar los datos en Firestore, en la colección 'items'
        await FirebaseFirestore.instance.collection('items').add({
          'description': description,
          'contact': contact,
          'imageUrl': imageUrl, // Guardar la URL de la imagen
          'timestamp': Timestamp.now(), // Añadir un timestamp
          'email': email,
          'titulo': titulo,
          'estado': estado
        });

        showSnackBar(scaffoldKey, 'Artículo guardado correctamente.');
      } else {
        showSnackBar(scaffoldKey, 'Error: La subida no fue exitosa.');
      }
    } catch (e) {
      showSnackBar(
          scaffoldKey, 'Error al subir la imagen y guardar en Firestore.');
      print('Error al subir la imagen y guardar en Firestore: $e');
    }
  }

  // Mo
  //strar mensajes usando SnackBar
  void showSnackBar(GlobalKey<ScaffoldState> scaffoldKey, String message) {
    ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> deletePost(BuildContext context, String postId,
      {String? imageUrl}) async {
    try {
      // Elimina el documento del posteo en la colección 'items'
      await FirebaseFirestore.instance.collection('items').doc(postId).delete();

      // Si también quieres eliminar una imagen asociada en Firebase Storage, hazlo aquí
      if (imageUrl != null) {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      }

      // Antes de usar el context, verifica que el widget aún esté montado
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post eliminado exitosamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el post: $e')),
        );
      }
    }
  }

  Future<DocumentSnapshot> getUserDocument(String email) async {
    return await FirebaseFirestore.instance
      .collection('usuario')
      .doc(email)
      .get();
  }

    // Función para actualizar el estado de la publicacion en Firestore
  Future<void> updateDonationStatus(String itemId, bool isDonated) async {
    await FirebaseFirestore.instance.collection('items').doc(itemId).update({
      'estado': isDonated,
    });
  }

  // Función para agregar un comentario a la colección 'comentarios' en Firestore
  Future<void> addComment({
    required String imageUrl,
    required String comentario,
    required String correo,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('comentarios').add({
        'imageUrl': imageUrl, // Asociar comentario con la imagen
        'comentario': comentario,
        'correo': correo,
        'timestamp': Timestamp.now(), // Agregar marca de tiempo
      });
    } catch (e) {
      print('Error al agregar comentario: $e');
    }
  }

    // Función para recuperar la imageUrl del usuario a partir del correo
  Future<String?> getUserImageUrl(String correo) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('usuario')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first['imageUrl']; // Devolver la imageUrl si existe
      } else {
        return null; // Si no se encuentra el usuario
      }
    } catch (e) {
      print('Error al obtener la imagen del usuario: $e');
      return null;
    }
  }
}
