import 'dart:io';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:intl/intl.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart'; // Para formatear las fechas.

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  
  // Función que autentica al usuario
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
      debugPrint(
          'Se produjo un error en la autenticación $e');
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
      debugPrint('Error creating user: $e');
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
        debugPrint(
            'No se encontró ningún usuario con el correo electrónico proporcionado');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
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

      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;

        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuario')
            .doc(docId)
            .get();
        if (doc.exists) {
          // Valida que se haya recuperado los datos
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('nombre')) {
            String firstName = data['nombre'] ?? correo;
            return firstName;
          } else {
            debugPrint(
                'Field "nombre" not found in the document.');
            return correo; // Valor por defecto
          }
        } else {
          debugPrint('Document does not exist.');
          return correo; // Valor por defecto
        }
      } else {
        debugPrint(
            'No document found with the provided email.');
        return correo; // Valor por defecto
      }
    } catch (e) {
      debugPrint('Error retrieving user data: $e');
      return correo;
    }
  }

  //Método que recupera todos los datos del usuario
  Future<Map<String, dynamic>?> getUserData(String correo) async {
    try {
      QuerySnapshot query = await _db
          .collection('usuario')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuario')
            .doc(docId)
            .get();
        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          return data; // Retorna los datos del usuario
        } else {
          debugPrint('Document does not exist.');
          return null; // Retorna null si el documento no existe
        }
      } else {
        debugPrint(
            'No document found with the provided email.');
        return null; // Retorna null si no se encuentra el documento
      }
    } catch (e) {
      debugPrint('Error retrieving user data: $e');
      return null;
    }
  }
  // Función que elimina la imagen de usuario
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
        if (imageUrl!.startsWith('https://firebasestorage.googleapis.com')) {
          try {
            // Crear una referencia a partir de la URL
            Reference storageRef =
                FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
          } catch (e) {
            debugPrint(
                'Error al eliminar la imagen de perfil: $e');
          }
        } else {
          debugPrint(
              'URL de imagen de perfil no válida o no presente');
        }
      } else {
        debugPrint(
            'Usuario no encontrado para el correo proporcionado');
      }

      // Eliminar imágenes relacionadas con el usuario desde la colección 'items'
      QuerySnapshot itemsSnapshot =
          await _db.collection('items').where('email', isEqualTo: correo).get();

      for (DocumentSnapshot itemDoc in itemsSnapshot.docs) {
        String? storagePath = itemDoc['storagePath'];
        if (storagePath!.isNotEmpty) {
          try {
            // Crear una referencia a partir del storagePath
            Reference storageRef = FirebaseStorage.instance.ref(storagePath);
            await storageRef.delete();
          } catch (e) {
            debugPrint(
                'Error al eliminar la imagen del item: $e');
          }
        } else {
          debugPrint(
              'No se encontró storagePath para el item con ID: ${itemDoc.id}');
        }
      }
    } catch (e) {
      debugPrint(
          'Error al eliminar las imágenes de Firebase Storage: $e');
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

      // Eliminar 'puntajes'
      QuerySnapshot puntajesSnapshot = await _db
          .collection('puntajes')
          .where('email', isEqualTo: correo)
          .get();

      QuerySnapshot feedbackSnapshot = await _db
          .collection('feedbacks')
          .where('emailUsuario', isEqualTo: correo)
          .get();

      QuerySnapshot historialSnapshot = await _db
          .collection('historial')
          .where('email', isEqualTo: correo)
          .get();

      QuerySnapshot recommendatiosSnapshot = await _db
          .collection('recommendations')
          .where('UserEmail', isEqualTo: correo)
          .get();

      // Eliminar todos los documentos en paralelo
      await Future.wait([
        ...postsSnapshot.docs.map((doc) => doc.reference.delete()),
        ...commentsSnapshot.docs.map((doc) => doc.reference.delete()),
        ...chatsSnapshot.docs.map((doc) => doc.reference.delete()),
        ...puntajesSnapshot.docs.map((doc) => doc.reference.delete()),
        ...feedbackSnapshot.docs.map((doc) => doc.reference.delete()),
        ...historialSnapshot.docs.map((doc) => doc.reference.delete()),
        ...recommendatiosSnapshot.docs.map((doc) => doc.reference.delete()),
      ]);

      // Añadir otras colecciones según sea necesario
    } catch (e) {
      debugPrint(
          'Error al eliminar los datos relacionados: $e');
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
      debugPrint('Error al eliminar el usuario: $e');
      return false;
    }
  }

  // Metodo para obtener los paises de la base de datos
  Future<List<String>> getPaises() async {
    try {
      final snapshot = await _db.collection('paises').get();
      return snapshot.docs.map((doc) => doc['nombre'] as String).toList();
    } catch (e) {
      debugPrint('Error al obtener países: $e');
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
      debugPrint('Error al cargar las ciudades: $e');
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
      debugPrint(
          'Error al recuperar el historial de chat: $e');
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
      debugPrint(
          'Error fetching interactions from Firestore: $e');
    }

    return interactions;
  }

  // Metodo que elimina los chats guardados del historial de chats
  Future<void> deleteChatById(String? chatId) async {
    // Verificar si chatId es null o vacío
    if (chatId == null || chatId.isEmpty) {
      debugPrint('ID de chat no válido: null o vacío.');
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
        debugPrint(
            'Chat con ID $chatId eliminado correctamente.');
      } else {
        // Si el documento no existe
        debugPrint(
            'No se encontró un chat con el ID $chatId para eliminar.');
      }
    } catch (e) {
      debugPrint('Error al eliminar el chat: $e');
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
      debugPrint(
          'Error al recuperar la imagen de perfil: $e');
      return null; // Devuelve null si no hay imagen o si ocurre un error
    }
  }

  Future<void> updateUserProfileImage(String correo, String downloadUrl) async {
    try {
      // Recupera el nombre del usuario
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'No hay un usuario autenticado';
      }

      // Selecciona una imagen del dispositivo del usuario
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        throw 'No se seleccionó ninguna imagen';
      }
      File imageFile = File(pickedFile.path);
      // Sube la imagen al storage de firebase
      String uid = user.uid;
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      // Recupera la url de la imagen para la descarga
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Nueva URL de la imagen: $downloadUrl');
      debugPrint(
          'Imagen de perfil actualizada correctamente');
    } catch (e) {
      debugPrint(
          'Error al actualizar la imagen de perfil: $e');
    }
  }

  // Función para verificar conectividad a Internet
  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    // ignore: unrelated_type_equality_checks
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> uploadImageAndSaveToFirestore(
      {required File imageFile,
      required String description,
      required String contact,
      required GlobalKey<ScaffoldState> scaffoldKey, // Para mostrar el SnackBar
      required String email,
      required String titulo,
      required bool estado,
      required int idpub}) async {
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
      // Generar una referencia única para la imagen en Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Subir la imagen a Firebase Storage
      UploadTask uploadTask = ref.putFile(imageFile);

      // Monitorear el progreso de la subida
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        Funciones.saveDebugInfo(
            'Progreso: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
      }, onError: (e) {
        showSnackBar(scaffoldKey, 'Error durante la subida de la imagen.');
      });

      // Esperar hasta que la subida se complete
      TaskSnapshot taskSnapshot = await uploadTask;
      if (taskSnapshot.state == TaskState.success) {
        // Obtener la URL de descarga solo si la subida fue exitosa
        final imageUrl = await ref.getDownloadURL();
        final storagePath = ref.fullPath; // Obtener el storagePath

        // Guardar los datos en Firestore, en la colección 'items'
        await FirebaseFirestore.instance.collection('items').add({
          'description': description,
          'contact': contact,
          'imageUrl': imageUrl, // Guardar la URL de la imagen
          'storagePath': storagePath, // Guardar el storagePath
          'timestamp': Timestamp.now(), // Añadir un timestamp
          'email': email,
          'titulo': titulo,
          'estado': estado,
          'idpub': idpub,
        });
      } else {
        debugPrint('Error: La subida no fue exitosa.');
      }
    } catch (e) {
      showSnackBar(
          scaffoldKey, 'Error al subir la imagen y guardar en Firestore.');
      debugPrint(
          'Error al subir la imagen y guardar en Firestore: $e');
    }
  }
  // Mostrar mensajes usando SnackBar
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

      // Eliminar los comentarios asociados al post (filtrados por imageUrl)
      QuerySnapshot comentariosSnapshot = await FirebaseFirestore.instance
          .collection('comentarios')
          .where('imageUrl', isEqualTo: imageUrl)
          .get();

      if (comentariosSnapshot.docs.isNotEmpty) {
        for (var doc in comentariosSnapshot.docs) {
          await doc.reference.delete(); // Eliminar cada comentario
        }
      } else {
        debugPrint(
            'No se encontraron comentarios asociados a la imagen: $imageUrl');
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

        Reference storageRef =
            FirebaseStorage.instance.ref().child(storagePath);
        await storageRef.delete();
      } catch (e) {
        debugPrint(
            'Error al eliminar la imagen de Firebase Storage: $e');
        // Opcional: Mostrar un mensaje al usuario o manejar el error según sea necesario
      }
    } catch (e) {
      // Manejar errores generales
      debugPrint(
          'Error al eliminar el post o los comentarios: $e');
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
      debugPrint('Error al agregar comentario: $e');
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
    } catch (e) {
      debugPrint('Error al eliminar el comentario: $e');
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
      debugPrint('Error al obtener el país del usuario: $e');
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

      // Si se seleccionó un nuevo archivo de imagen, subir a Firebase Storage
      if (imageFilePath != null) {
        // Elimina la imagen anterior de Firebase Storage si existe
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await _deleteImageFromFirebase(oldImageUrl);
        }

        // sube la nueva imagen a Firebase Storage
        String downloadUrl = await uploadImageToFirebase(imageFilePath);
        dataToUpdate['imageUrl'] = downloadUrl; // Actualiza el campo imageUrl
      }

      // Actualiza los datos en Firestore
      await _db.collection('items').doc(itemId).update(dataToUpdate);
    } catch (e) {
      debugPrint("Error al actualizar la publicación: $e");
    }
  }

  Future<void> _deleteImageFromFirebase(String imageUrl) async {
    try {
      // Obtiene la referencia de la imagen en Firebase Storage
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } catch (e) {
      debugPrint("Error al eliminar la imagen anterior: $e");
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
        // Si el documento no existe, retorna la imagen predeterminada
        return 'assets/images/perfil.png';
      }
    } catch (e) {
      debugPrint('Error al cargar la imagen de perfil: $e');
      return 'assets/images/perfil.png'; // En caso de error, usar imagen por defecto
    }
  }

  // Función que carga la lista de paises
  Future<List<String>> cargarPaises() async {
    try {
      List<String> paises = await getPaises();
      return paises;
    } catch (e) {
      debugPrint('Error al cargar países: $e');
      return [];
    }
  }

  // Función para guardar o actualizar el puntaje en Firestore
  Future<void> saveOrUpdateScore(BuildContext context, int puntos) async {
    User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no logueado');
      }
      String userId =
          user.email!;
    try {
      // Verificar si el usuario ya tiene un puntaje registrado
      final QuerySnapshot existingScore = await _db
          .collection('puntajes')
          .where('email', isEqualTo: userId)
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
        if (context.mounted) {
          showCustomSnackBar(context, '¡Puntaje actualizado correctamente!',
              SnackBarType.confirmation);
        }
      } else {
        // Si no existe un registro, crear uno nuevo
        await _db.collection('puntajes').add({
          'email': user.email,
          'puntos': puntos,
          'fecha': DateTime.now(),
        });
        if (context.mounted) {
          showCustomSnackBar(context, '¡Puntaje guardado correctamente!',
              SnackBarType.confirmation,
              durationInMilliseconds: 3000);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCustomSnackBar(
            context, 'Error al guardar puntaje: $e', SnackBarType.error,
            durationInMilliseconds: 3000);
      }
    }
    }
  Future<int> getCurrentUserScore(BuildContext context) async {
    try {
      // Obtener el ID del usuario logueado (user UID)
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no logueado');
      }
      String userId =
          user.email!;

      // Consultar Firestore para obtener el puntaje del usuario usando el campo "userId"
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('puntajes')
          .where('email', isEqualTo: userId)
          .get();

      // Verificar si se encontró algún documento
      if (querySnapshot.docs.isNotEmpty) {
        // Suponiendo que cada usuario tiene solo un documento en la colección "puntajes"
        DocumentSnapshot userScoreSnapshot = querySnapshot.docs.first;
        Map<String, dynamic> userData =
            userScoreSnapshot.data() as Map<String, dynamic>;

        // Verificar si el campo "puntos" está presente en los datos
        if (userData.containsKey('puntos')) {
          debugPrint(
              'Puntaje encontrado: ${userData['puntos']}');
          return userData['puntos'] as int;
        } else {
          debugPrint(
              'El campo "puntos" no se encuentra en los datos.');
        }
      } else {
        debugPrint(
            'No se encontró ningún documento para el userId: $userId');
      }

      // Retornar 0 si no hay puntaje guardado o el documento no existe
      return 0;
    } catch (e) {
      // Manejar errores y retornar 0 en caso de fallo
      debugPrint(
          'Error al obtener el puntaje del usuario: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getResumenReciclado(String email) async {
    final querySnapshot = await _db
        .collection('historial')
        .where('email', isEqualTo: email)
        .get();

    Map<String, int> resumen = {};
    for (var doc in querySnapshot.docs) {
      String material = doc['item'];
      resumen[material] = (resumen[material] ?? 0) + 1;
    }
    return resumen;
  }

  Future<Map<String, int>> getTotalesPorFecha(
      String email, DateTime inicio, DateTime fin) async {
    // Obtener documentos del rango de fechas y del usuario especificado
    final query = await FirebaseFirestore.instance
        .collection('historial')
        .where('email', isEqualTo: email)
        .where('fecha', isGreaterThanOrEqualTo: inicio)
        .where('fecha', isLessThanOrEqualTo: fin)
        .get();

    // Crear un mapa para contar los elementos agrupados por material
    final Map<String, int> totales = {};
    for (var doc in query.docs) {
      final material = doc['item'] as String;

      if (!totales.containsKey(material)) {
        totales[material] = 0;
      }
      // Incrementar el conteo por cada documento del material
      totales[material] = totales[material]! + 1;
    }

    return totales;
  }

  /// Recupera las recomendaciones del usuario ordenadas por timestamp.
  Stream<QuerySnapshot> getUserRecommendations(String userEmail) {
    return _db
        .collection('recommendations')
        .where('userEmail', isEqualTo: userEmail)
        .snapshots();
  }

  static Future<void> saveScannedItem(
      {required BuildContext context,
      required String detectedItem,
      String? chatResponse,
      required String userEmail,
      required String itemName}) async {
    try {
      // Formatear la fecha
      final formattedDate =
          DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

      await FirebaseFirestore.instance.collection('historial').add({
        'item': detectedItem, // Objeto escaneado
        'descripcion': (chatResponse ?? 'Sin descripción disponible').trim(),
        'email': userEmail, // Email del usuario logueado
        'fecha': formattedDate, // Fecha formateada
        'material': itemName
      });

      // Mostrar SnackBar de confirmación
      showCustomSnackBar(
        context,
        'Ítem guardado exitosamente',
        SnackBarType.confirmation,
      );
    } catch (e) {
      // Mostrar SnackBar de error
      showCustomSnackBar(
        context,
        'Error al guardar el ítem: $e',
        SnackBarType.error,
      );
      rethrow; // Lanza el error nuevamente si se necesita manejarlo más adelante
    }
  }

  static Future<void> saveRecommendation({
    required BuildContext context,
    required String chatResponse,
    required String userEmail,
    required String item,
  }) async {
    try {
      final recommendationData = {
        'recommendation': chatResponse,
        'userEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'item': item,
      };

      await FirebaseFirestore.instance
          .collection('recommendations')
          .add(recommendationData);
    } catch (e) {
      debugPrint('Error al guardar la recomendación: $e');
      throw Exception(
          'No se pudo guardar la recomendación. Verifica tu conexión.');
    }
  }

  Future<void> deleteUserRecommendation(String userEmail, String docId) async {
    try {
      final path = 'recommendations/$docId';
      final docRef = FirebaseFirestore.instance.doc(path);

      // Verifica si el documento existe
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        debugPrint('El documento con ID $docId no existe en Firestore.');
        throw Exception('El documento no existe.');
      }

      debugPrint('Eliminando documento en ruta: $path');
      await docRef.delete();
      debugPrint('Documento eliminado correctamente en Firestore.');
    } catch (e) {
      debugPrint('Error al eliminar documento: $e');
      rethrow; // Propaga el error para que pueda ser manejado por la función que llama
    }
  }
}
