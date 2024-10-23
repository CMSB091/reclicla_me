import 'dart:io';
import 'package:path/path.dart';
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
  final User? user = FirebaseAuth.instance.currentUser;
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
    String correo,
    String? imageUrl,
  ) async {
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
          'imageUrl':
              imageUrl ?? 'assets/images/perfil.png', // Actualiza imageUrl
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

  Future<void> _deleteUserImages(String correo) async {
    try {
      // Eliminar imagen de perfil desde la colección 'usuario'
      QuerySnapshot userSnapshot = await _db
          .collection('usuario')
          .where('correo', isEqualTo: correo)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userSnapshot.docs.first;
        String? imageUrl = userDoc['imageUrl'];
        print('imageUrl $imageUrl');

        if (imageUrl != null &&
            imageUrl.startsWith('https://firebasestorage.googleapis.com')) {
          try {
            // Crear una referencia a partir de la URL
            Reference storageRef =
                FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
            print('Imagen de perfil eliminada: $imageUrl');
          } catch (e) {
            print('Error al eliminar la imagen de perfil: $e');
          }
        } else {
          print('URL de imagen de perfil no válida o no presente');
        }
      } else {
        print('Usuario no encontrado para el correo proporcionado');
      }

      // Eliminar imágenes relacionadas con el usuario desde la colección 'items'
      QuerySnapshot itemsSnapshot = await _db
          .collection('items')
          .where('email', isEqualTo: correo)
          .get();

      for (DocumentSnapshot itemDoc in itemsSnapshot.docs) {
        String? storagePath = itemDoc['storagePath'];
        print('storagePath $storagePath');

        if (storagePath != null && storagePath.isNotEmpty) {
          try {
            // Crear una referencia a partir del storagePath
            Reference storageRef = FirebaseStorage.instance.ref(storagePath);
            await storageRef.delete();
            print('Imagen del item eliminada: $storagePath');
          } catch (e) {
            print('Error al eliminar la imagen del item: $e');
          }
        } else {
          print(
              'No se encontró storagePath para el item con ID: ${itemDoc.id}');
        }
      }
    } catch (e) {
      print('Error al eliminar las imágenes de Firebase Storage: $e');
    }
  }

  // Funcion para eliminar los datos relacionados del socio
  Future<void> _deleteUserRelatedData(String correo) async {
    try {
      // Eliminar 'posts'
      QuerySnapshot postsSnapshot =
          await _db.collection('items').where('email', isEqualTo: correo).get();

      // Eliminar 'comments'
      QuerySnapshot commentsSnapshot = await _db
          .collection('comentarios')
          .where('correo', isEqualTo: correo)
          .get();

      // Eliminar 'likes'
      QuerySnapshot chatsSnapshot = await _db
          .collection('chat_interactions')
          .where('email', isEqualTo: correo)
          .get();

      // Eliminar todos los documentos en paralelo
      await Future.wait([
        ...postsSnapshot.docs.map((doc) => doc.reference.delete()),
        ...commentsSnapshot.docs.map((doc) => doc.reference.delete()),
        ...chatsSnapshot.docs.map((doc) => doc.reference.delete()),
      ]);

      // Añadir otras colecciones según sea necesario
    } catch (e) {
      print('Error al eliminar los datos relacionados: $e');
    }
  }

  Future<bool> deleteUser(String correo) async {
    try {
      // Obtener el usuario
      QuerySnapshot snapshot = await _db
          .collection('usuario')
          .where('correo', isEqualTo: correo)
          .get();

      if (snapshot.docs.isNotEmpty) {
        DocumentReference userRef = snapshot.docs.first.reference;

        // Paso 1: Eliminar imágenes asociadas (perfil e items)
        await _deleteUserImages(correo);

        // Paso 2: Borrar documentos relacionados en otras colecciones
        await _deleteUserRelatedData(correo);

        // Paso 3: Eliminar el documento principal del usuario
        await userRef.delete();

        return true;
      } else {
        return false; // No se encontró el usuario con el correo especificado
      }
    } catch (e) {
      print('Error al eliminar el usuario: $e');
      return false;
    }
  }

  // Metodo para obtener los paises de la base de datos
  Future<List<String>> getPaises() async {
    try {
      final snapshot = await _db.collection('paises').get();
      return snapshot.docs.map((doc) => doc['nombre'] as String).toList();
    } catch (e) {
      //await Funciones.SeqLog('error', 'Error al obtener países: $e');
      print('Error al obtener países: $e');
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
      //await Funciones.SeqLog('error', 'Error al cargar las ciudades: $e');
      print('Error al cargar las ciudades: $e');
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

  Future<void> uploadImageAndSaveToFirestore({
    required File imageFile,
    required String description,
    required String contact,
    required GlobalKey<ScaffoldState> scaffoldKey, // Para mostrar el SnackBar
    required String email,
    required String titulo,
    required bool estado,
  }) async {
    // Verificar conexión a Internet antes de subir la imagen
    print('Paso 1');
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      showSnackBar(scaffoldKey, 'No tienes conexión a Internet.');
      return;
    }
    print('Paso 2');
    try {
      // Verificar si el archivo existe
      if (!await imageFile.exists()) {
        showSnackBar(
            scaffoldKey, 'El archivo no existe en la ruta especificada.');
        return;
      }
      print('Paso 3');
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
        final storagePath = ref.fullPath; // Obtener el storagePath

        print('URL de la imagen subida: $imageUrl');
        print('Storage path de la imagen subida: $storagePath');

        // Guardar los datos en Firestore, en la colección 'items'
        await FirebaseFirestore.instance.collection('items').add({
          'description': description,
          'contact': contact,
          'imageUrl': imageUrl, // Guardar la URL de la imagen
          'storagePath': storagePath, // Guardar el storagePath
          'timestamp': Timestamp.now(), // Añadir un timestamp
          'email': email,
          'titulo': titulo,
          'estado': estado
        });
      } else {
        print('Error: La subida no fue exitosa.');
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

  Future<void> deletePost(BuildContext context, String itemId,
      {required String imageUrl}) async {
    try {
      // Eliminar el post de la colección "items"
      await FirebaseFirestore.instance.collection('items').doc(itemId).delete();
      print('Post eliminado, intentando eliminar los comentarios...');
      print('imageUrl $imageUrl');

      // Eliminar los comentarios asociados al post (filtrados por imageUrl)
      QuerySnapshot comentariosSnapshot = await FirebaseFirestore.instance
          .collection('comentarios')
          .where('imageUrl', isEqualTo: imageUrl)
          .get();

      print('Comentarios recuperados: ${comentariosSnapshot.docs.length}');

      if (comentariosSnapshot.docs.isNotEmpty) {
        for (var doc in comentariosSnapshot.docs) {
          print('Eliminando comentario con ID: ${doc.id}');
          await doc.reference.delete(); // Eliminar cada comentario
        }
      } else {
        print('No se encontraron comentarios asociados a la imagen: $imageUrl');
      }

      // Eliminar la imagen de Firebase Storage
      try {
        // Parsear el storage path desde el imageUrl
        // Ejemplo imageUrl: https://firebasestorage.googleapis.com/v0/b/tu-app.appspot.com/o/images%2Fitem1.jpg?alt=media&token=...
        Uri uri = Uri.parse(imageUrl);
        String? fullPath = uri.pathSegments
            .skipWhile((segment) => segment != 'o')
            .skip(1)
            .join('/')
            .split('?')
            .first;
        String storagePath = Uri.decodeFull(fullPath);

        print('Storage path: $storagePath');

        Reference storageRef =
            FirebaseStorage.instance.ref().child(storagePath);
        await storageRef.delete();
        print('Imagen eliminada de Firebase Storage');
      } catch (e) {
        print('Error al eliminar la imagen de Firebase Storage: $e');
        // Opcional: Mostrar un mensaje al usuario o manejar el error según sea necesario
      }
      // Mostrar un mensaje de éxito
      print('Post, comentarios y imagen eliminados correctamente');
    } catch (e) {
      // Manejar errores generales
      print('Error al eliminar el post o los comentarios: $e');
      // Opcional: Mostrar un mensaje al usuario
    }
  }

  // Cargar el documento del usuario desde Firestore
  Future<DocumentSnapshot> getUserDocument(String email) async {
    try {
      return await _db.collection('usuarios').doc(email).get();
    } catch (e) {
      rethrow;
    }
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
  Future<String?> getUserImageUrl(String email) async {
    try {
      // Obtener la referencia a la imagen desde la carpeta profile_images en Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/$email.jpg'); // Cambiar a profile_images

      // Obtener la URL de descarga de la imagen
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Si ocurre un error, retornar null y manejar la imagen predeterminada en el UI
      debugPrint('Error al obtener la URL de la imagen: $e');
      return null;
    }
  }

  // Función para eliminar un comentario
  Future<void> deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('comentarios')
          .doc(commentId)
          .delete();
      print('Comentario eliminado con éxito.');
    } catch (e) {
      print('Error al eliminar el comentario: $e');
    }
  }

  Future<String> getPaisFromUsuario(String email) async {
    // Realiza la consulta en la colección 'usuario' para obtener el campo 'pais'
    try {
      final usuarioSnapshot = await FirebaseFirestore.instance
          .collection('usuario')
          .where('correo', isEqualTo: email)
          .limit(1)
          .get();

      if (usuarioSnapshot.docs.isNotEmpty) {
        final usuarioData = usuarioSnapshot.docs.first.data();
        return usuarioData['pais'] ??
            'Desconocido'; // Recuperar el campo 'pais'
      }
    } catch (e) {
      print('Error al obtener el país del usuario: $e');
    }
    return 'Desconocido'; // Devolver 'Desconocido' en caso de error
  }

  Future<void> updatePost(
    String itemId,
    String titulo,
    String description,
    String contact,
    String? imageFilePath, // Path del archivo local si se seleccionó uno
    String? oldImageUrl, // URL de la imagen anterior
  ) async {
    try {
      Map<String, dynamic> dataToUpdate = {
        'titulo': titulo,
        'description': description,
        'contact': contact,
        'updatedAt': FieldValue.serverTimestamp(), // Timestamp de actualización
      };

      // Si se seleccionó un nuevo archivo de imagen, súbelo a Firebase Storage
      if (imageFilePath != null) {
        // Eliminar la imagen anterior de Firebase Storage si existe
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await _deleteImageFromFirebase(oldImageUrl);
        }

        // Subir la nueva imagen a Firebase Storage
        String downloadUrl = await uploadImageToFirebase(imageFilePath);
        dataToUpdate['imageUrl'] = downloadUrl; // Actualizar el campo imageUrl
      }

      // Actualizar los datos en Firestore
      await _db.collection('items').doc(itemId).update(dataToUpdate);

      print("Publicación actualizada con éxito");
    } catch (e) {
      print("Error al actualizar la publicación: $e");
    }
  }

  Future<void> _deleteImageFromFirebase(String imageUrl) async {
    try {
      // Obtener la referencia de la imagen en Firebase Storage
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      print("Imagen anterior eliminada con éxito.");
    } catch (e) {
      print("Error al eliminar la imagen anterior: $e");
    }
  }

  // Función que carga la lista de paises
  Future<String> uploadImageToFirebase(String imageFilePath) async {
    try {
      File file = File(imageFilePath);
      String fileName = basename(imageFilePath);

      // Subir a la carpeta 'images' en Firebase Storage
      UploadTask task =
          FirebaseStorage.instance.ref('images/$fileName').putFile(file);

      TaskSnapshot snapshot = await task;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir la imagen: $e');
    }
  }

  // Función para obtener la URL de la imagen desde la colección 'usuarios'
  Future<String?> loadUserProfileImage(String email) async {
    try {
      // Obtener el documento del usuario desde Firestore
      DocumentSnapshot snapshot =
          await _db.collection('usuario').doc(email).get();
      if (snapshot.exists) {
        // Convertir los datos a un Map<String, dynamic>
        final data = snapshot.data() as Map<String, dynamic>?;

        // Retornar la URL de la imagen si existe, o una imagen predeterminada
        return data?['imageUrl'] ?? 'assets/images/perfil.png';
      } else {
        // Si el documento no existe, retornar la imagen predeterminada
        return 'assets/images/perfil.png';
      }
    } catch (e) {
      print('Error al cargar la imagen de perfil: $e');
      return 'assets/images/perfil.png'; // En caso de error, usar imagen por defecto
    }
  }

  // Función que carga la lista de paises
  Future<List<String>> cargarPaises() async {
    try {
      List<String> paises = await getPaises();
      Funciones.SeqLog('information', paises.toString());
      return paises;
    } catch (e) {
      Funciones.SeqLog('error', 'Error al cargar países: $e');
      return [];
    }
  }

  // Función para guardar o actualizar el puntaje en Firestore
  Future<void> saveOrUpdateScore(BuildContext context, int puntos) async {
    if (user != null) {
      try {
        // Verificar si el usuario ya tiene un puntaje registrado
        final QuerySnapshot existingScore = await _db
            .collection('puntajes')
            .where('email', isEqualTo: user!.email)
            .get();

        if (existingScore.docs.isNotEmpty) {
          // Si ya existe un registro para el usuario, actualizar el puntaje y la fecha
          await _db
              .collection('puntajes')
              .doc(existingScore.docs.first.id)
              .update({
            'puntos': puntos,
            'fecha': DateTime.now(),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Puntaje actualizado correctamente!')),
          );
        } else {
          // Si no existe un registro, crear uno nuevo
          await _db.collection('puntajes').add({
            'email': user!.email,
            'puntos': puntos,
            'fecha': DateTime.now(),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Puntaje guardado correctamente!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar puntaje: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no logueado')),
      );
    }
  }
  
}
