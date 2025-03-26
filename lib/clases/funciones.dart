import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/configuracion/config.dart';
import 'package:recila_me/widgets/inicio.dart';
import 'package:recila_me/widgets/itemDetailScreen.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:http/http.dart' as http;
import 'package:recila_me/widgets/resumenes.dart';
import 'package:recila_me/widgets/showCustomSnackBar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

final FirestoreService firestoreService = FirestoreService();

class Funciones {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  // Palabras clave relacionadas con reciclaje.
  static final List<String> recyclingKeywords = [
    'reciclaje',
    'reciclar',
    'reutilizar',
    'sostenible',
    'casa',
    'hogar',
    'materiales',
    'botella',
    'plástico',
    'papel',
    'cartón',
    'vidrio',
    'lata',
    'metal',
    'residuos',
    'desechos',
    'decoración',
    'manualidades',
    'ecología',
    'basura',
    'compostaje',
    'pila',
    'pilas, gracias, imagen'
  ];

  Map<String, String> materialInfo = {
    'Plastico': 'assets/images/reciclaje_botellas.png',
    'Vidrio': 'assets/images/reciclaje_vidrio.png',
    'Metal': 'assets/images/background_metal.png',
    'Aluminio': 'assets/images/aluminios_reciclar.png',
    'Carton': 'assets/images/basura_carton.png',
    'Isopor': 'assets/images/isopor_waste.png',
    'Papel': 'assets/images/paper_recycling.png',
    'Residuos': 'assets/images/recycle_general.png',
  };
  // Función que prepara el prompt parala API de la IA
  String generateImagePromptFromResponse(String chatGPTResponse) {
    if (chatGPTResponse.contains('plástico')) {
      return 'Imagen de varios objetos de plástico';
    } else if (chatGPTResponse.contains('vidrio')) {
      return 'Imagen de varios objetos de vidrio';
    } else if (chatGPTResponse.contains('papel')) {
      return 'Imagen de varios objetos de papel';
    } else if (chatGPTResponse.contains('metal')) {
      return 'Imagen de varios objetos de metal';
    } else {
      return 'Una ilustración que muestre diversas actividades de reciclaje, como la clasificación de diferentes materiales como plástico, vidrio, metal y papel para su reutilización. La imagen debe enfatizar la sostenibilidad y el impacto ambiental.';
    }
  }

  Future<bool> verificarPermisosAlmacenamiento() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted ||
          await Permission.storage.isGranted) {
        return true;
      }

      if (await Permission.manageExternalStorage.request().isGranted ||
          await Permission.storage.request().isGranted) {
        return true;
      }
    }

    return false;
  }

  // Función para cerrar sesón
  static Future<void> simulateLogout(BuildContext context) async {
    // Muestra el diálogo de cierre de sesión
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(
                'Cerrando sesión...',
                style: TextStyle(
                  fontFamily: 'Artwork',
                  fontSize: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 3));
    try {
      // Cierra la sesión del usuario
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    } finally {
      // Cierra el diálogo
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        // Redirige a la página de login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginApp(),
          ),
        );
      }
    }
  }

  // Función que retorna la respuesta de la API
  static Future<String> getChatGPTResponse(String prompt) async {
    const apiKey = Config.openaiApiKey; //dotenv.env['OPENAI_API_KEY'];
    const apiUrl = 'https://api.openai.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: utf8.encode(jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1000,
      })),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      debugPrint(
          'Error ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
      throw Exception('Failed to load ChatGPT response');
    }
  }

  static Future<String> fetchChatGPTResponse(
      String prompt, bool isRecyclingRelated) async {
    List<Map<String, String>> recentInteractions =
        await firestoreService.fetchInteractionsFromFirestore();
    String context = recentInteractions.map((interaction) {
      return 'User: ${interaction['userPrompt']}\nBot: ${interaction['chatResponse']}';
    }).join('\n\n');

    String finalPrompt = '$context\n\nUser: $prompt\nBot:';

    if (isRecyclingRelated) {
      String response = await getChatGPTResponse(finalPrompt);
      return response;
    } else {
      return 'Por favor, realiza una consulta relacionada con el reciclaje de materiales en el hogar y cómo reutilizarlos de manera creativa.';
    }
  }

  // Genera imagenes con la ayuda de la IA
  static Future<String> fetchGeneratedImage(String prompt) async {
    const apiKey = Config.openaiApiKey; //dotenv.env['OPENAI_API_KEY'];
    const apiUrl = 'https://api.openai.com/v1/images/generations';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'prompt': prompt,
        'n': 1, // Número de imágenes a generar
        'size': '512x512', // Tamaño de la imagen
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final imageUrlGenerated = data['data'][0]['url'];
      return imageUrlGenerated;
    } else {
      debugPrint('Error al generar la imagen: ${response.statusCode}');
      return '';
    }
  }

  Future<void> cargarDatosUsuario({
    required User? user,
    required TextEditingController nombreController,
    required TextEditingController apellidoController,
    required TextEditingController edadController,
    required TextEditingController direccionController,
    required TextEditingController ciudadController,
    required TextEditingController paisController,
    required TextEditingController telefonoController,
    required Function setLoadingState,
  }) async {
    setLoadingState(true);

    try {
      if (user != null) {
        String correo = user.email.toString();
        Map<String, dynamic>? userData =
            await _firestoreService.getUserData(correo);

        nombreController.text = userData!['nombre'] ?? '';
        apellidoController.text = userData['apellido'] ?? '';
        edadController.text = (userData['edad'] ?? '').toString();
        direccionController.text = userData['direccion'] ?? '';
        ciudadController.text = userData['ciudad'] ?? '';
        paisController.text = userData['pais'] ?? '';
        telefonoController.text = userData['telefono'] ?? '';
      }
    } catch (e) {
      debugPrint('Se ha producido un error al cargar los datos del usuario $e');
    } finally {
      setLoadingState(false);
    }
  }

  Future<void> guardarDatos({
    required String correo,
    required TextEditingController nombreController,
    required TextEditingController apellidoController,
    required TextEditingController edadController,
    required TextEditingController direccionController,
    required TextEditingController ciudadController,
    required TextEditingController paisController,
    required TextEditingController telefonoController,
    required String? imageUrl, // imageUrl como parámetro requerido
    required Function setSavingState,
    required BuildContext context,
    required List<CameraDescription> cameras,
  }) async {
    if (nombreController.text.isNotEmpty &&
        apellidoController.text.isNotEmpty) {
      setSavingState(true);
      try {
        String nombre = nombreController.text;
        String apellido = apellidoController.text;
        int edad = int.parse(edadController.text);
        String direccion = direccionController.text;
        String ciudad = ciudadController.text;
        String pais = paisController.text;
        String telefono = telefonoController.text;

        // Verifica que el imageUrl no sea nulo
        String finalImageUrl = imageUrl ?? 'assets/images/perfil.png';

        // Actualiza los datos del usuario incluyendo imageUrl
        bool result = await _firestoreService.updateUser(
          nombre,
          apellido,
          edad,
          direccion,
          ciudad,
          pais,
          telefono,
          correo,
          finalImageUrl, // URL de la imagen aquí
        );

        if (result) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Datos Guardados'),
                  content: Text(
                      'Nombre: $nombre\nApellido: $apellido\nEdad: $edad\nDirección: $direccion\nCiudad: $ciudad\nPaís: $pais\nTeléfono: $telefono'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyInicio(
                              cameras: cameras,
                            ),
                          ),
                        );
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          if (context.mounted) {
            showCustomSnackBar(
                context, 'Error al guardar los datos.', SnackBarType.error,
                durationInMilliseconds: 3000);
          }
        }
      } catch (e) {
        if (context.mounted) {
          showCustomSnackBar(context, 'Error: $e', SnackBarType.error,
              durationInMilliseconds: 3000);
        }
      } finally {
        setSavingState(false);
      }
    }
  }

  Future<void> pickAndUploadImage({
    required String correo,
    required Function(String) onImageUploaded,
    required BuildContext context,
  }) async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      try {
        // Subir la imagen a Firebase Storage en la carpeta 'profile_images'
        final ref = _storage.ref().child('profile_images/$correo.jpg');
        await ref.putFile(File(pickedImage.path));

        // Obtener la URL de la imagen subida
        final downloadUrl = await ref.getDownloadURL();

        // Actualizar la imagen en Firestore o donde la almacenes
        await _firestoreService.updateUserProfileImage(correo, downloadUrl);

        // Callback para actualizar la URL de la imagen
        onImageUploaded(downloadUrl);

        // Mostrar éxito
        showCustomSnackBar(
            context,
            'Imagen de perfil actualizada correctamente',
            SnackBarType.confirmation,
            durationInMilliseconds: 3000);
      } catch (e) {
        // Mostrar error
        showCustomSnackBar(
            context, 'Error al subir la imagen: $e', SnackBarType.error,
            durationInMilliseconds: 3000);
      }
    }
  }

  //Función para navegar a la página de detalles del artículo
  void navigateToItemDetail(
      BuildContext context,
      String imageUrl,
      String title,
      String description,
      String contact,
      String username,
      bool estado,
      String email,
      String pais,
      String idpub) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(
            imageUrl: imageUrl,
            title: title,
            description: description,
            contact: contact,
            userName: username,
            estado: estado,
            email: email,
            pais: pais,
            idpub: idpub),
      ),
    );
  }

  // Función para formatear el Timestamp de Firestore a una fecha legible
  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  void launchWhatsApp(String contact, String country, BuildContext context,
      String id, String title, String imageUrl) async {
    try {
      // Eliminar caracteres no numéricos y formatear el número
      String phoneNumber = contact.replaceAll(RegExp(r'[^\d+]'), '');

      // Mapa de códigos de país según el país
      Map<String, String> countryCodes = {
        'Chile': '56',
        'Argentina': '54',
        'Uruguay': '598',
        'Brasil': '55',
        'Paraguay': '595',
      };

      // Verificar si el país está en la lista de códigos y agregar el código de país si no está presente
      if (!countryCodes.containsKey(country)) {
        showCustomSnackBar(context, 'El país no está soportado para WhatsApp',
            SnackBarType.error,
            durationInMilliseconds: 3000);
        return; // Si no hay código para el país, salir de la función
      }

      // Si el número no empieza con el código de país, agregar
      if (!phoneNumber.startsWith(countryCodes[country]!)) {
        phoneNumber = '${countryCodes[country]}${phoneNumber.substring(1)}';
      }

      // Se define el mensaje a enviar, incluyendo el enlace de la imagen
      String message = Uri.encodeComponent(
          '¡Hola, estoy interesado en la publicación con código número $id. Título: $title. Aquí puedes ver la imagen: $imageUrl');

      // URL usando el esquema `https://wa.me/`
      final Uri whatsappWebUri =
          Uri.parse('https://wa.me/$phoneNumber?text=$message');

      // Se verifica si se puede abrir WhatsApp mediante un esquema alternativo
      if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } else {
        showCustomSnackBar(
            context,
            'No se pudo abrir WhatsApp con el esquema web. Asegúrate de que está instalado.',
            SnackBarType.error,
            durationInMilliseconds: 3000);
      }
    } catch (e) {
      // Manejo de errores
      showCustomSnackBar(
          context, 'Error al intentar abrir WhatsApp: $e', SnackBarType.error,
          durationInMilliseconds: 3000);
    }
  }

  static Future<File?> pickImageFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      debugPrint('Imagen seleccionada: ${pickedImage.path}');
      return File(pickedImage.path); // Devolver el archivo seleccionado
    } else {
      // Mostrar SnackBar si no se selecciona imagen
      showCustomSnackBar(
          context, 'No se seleccionó ninguna imagen.', SnackBarType.error,
          durationInMilliseconds: 3000);
      return null; // Devolver null si no se seleccionó ninguna imagen
    }
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color color = Colors.green, // Color del fondo del SnackBar
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // Estilo del texto
        ),
        behavior: SnackBarBehavior.floating, // Hace que el SnackBar "flote"
        margin: const EdgeInsets.all(16), // Margen alrededor del SnackBar
        backgroundColor: color, // Color de fondo dinámico
        duration: const Duration(seconds: 3), // Duración de la animación
      ),
    );
  }

  // Función para mostrar el modal de reglas del juego
  void showGameRules(BuildContext context, String cabecera, String cuerpo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(cabecera),
          content: Text(cuerpo),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void showLoadingSpinner(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Evita que el usuario cierre el diálogo tocando fuera de él
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  // Genera un residuo aleatorio
  Map<String, dynamic> generarResiduoAleatorio(
      List<Map<String, dynamic>> residuos) {
    final random = Random();
    return residuos[random.nextInt(residuos.length)];
  }

// Verifica la respuesta y retorna el puntaje actualizado y el estado de la verificación
  int verificarRespuesta(
      String tipoBasurero, String residuoActual, int puntos) {
    if (tipoBasurero == residuoActual) {
      return puntos + 1;
    } else {
      return puntos > 0 ? puntos - 1 : 0;
    }
  }

// Función para mostrar un diálogo de confirmación
  Future<bool> showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar guardado'),
          content: const Text(
              'El puntaje que has conseguido es menor al que ya tienes guardado. ¿Deseas reemplazarlo de todas formas?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  Future<void> writeDebugFile(
      String fileName, Map<String, dynamic> content) async {
    try {
      // Obtener el directorio de Descargas (para Android) o Documentos (para iOS)
      final directory = await getExternalStorageDirectory(); // Para Android

      // Para iOS o en caso de no tener permisos en Descargas, usar Documentos
      final safeDirectory =
          directory ?? await getApplicationDocumentsDirectory();
      final filePath = '${safeDirectory.path}/$fileName';

      // Crea el archivo y escribe el contenido JSON
      final file = File(filePath);
      await file.writeAsString(json.encode(content), flush: true);
    } catch (e) {
      debugPrint("Error al escribir el archivo de debug: $e");
    }
  }

  static Future<void> saveDebugInfo(String message,
      {Map<String, dynamic>? additionalData}) async {
    try {
      // Obtiene el directorio de Descargas (para Android) o Documentos (para iOS)
      final directory = await getExternalStorageDirectory();
      final safeDirectory =
          directory ?? await getApplicationDocumentsDirectory();
      final filePath = '${safeDirectory.path}/debug_log.json';

      final file = File(filePath);

      // Crea una nueva entrada de depuración con el mensaje y la marca de tiempo
      final debugEntry = {
        "message": message,
        "timestamp": DateTime.now().toIso8601String(),
        "additionalData": additionalData ?? {}
      };

      Map<String, dynamic> debugLog = {};

      // Lee el contenido actual del archivo si existe
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        debugLog = jsonString.isNotEmpty ? json.decode(jsonString) : {};
      }

      // Agrega la nueva entrada con un identificador único (timestamp)
      debugLog[DateTime.now().toIso8601String()] = debugEntry;

      // Escribe el archivo con la nueva entrada
      await file.writeAsString(json.encode(debugLog), flush: true);
    } catch (e) {
      debugPrint("Error al guardar la información de depuración: $e");
    }
  }

  static void initializeAnimations(
    AnimationController titleController,
    AnimationController countController,
    AnimationController arrowController,
    TickerProvider vsync,
  ) {
    titleController.duration = const Duration(seconds: 2);
    countController.duration = const Duration(seconds: 3);
    arrowController.duration = const Duration(seconds: 1);
  }

  static void startTitleAnimation(
      AnimationController titleController, VoidCallback onComplete) {
    titleController.forward().whenComplete(onComplete);
  }

  static void startCountAnimation(
    AnimationController countController,
    Animation<int> countAnimation,
    VoidCallback onCompletion,
    VoidCallback onValueChange,
  ) {
    countController.reset();
    countAnimation.addListener(onValueChange);
    countAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onCompletion();
      }
    });
    countController.forward();
  }

  static Future<void> playCompletionSound(AudioPlayer audioPlayer) async {
    await audioPlayer.play(AssetSource('audio/congrats.mp3'));
  }

  static Future<void> vibrateOnCompletion() async {
    if (await Vibrate.canVibrate) {
      Vibrate.vibrate();
    }
  }

  void navigateToNextPage(BuildContext context, int nextPage, String elemento) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReusableCountSplashScreen(
          backgroundImagePath:
              materialInfo[elemento] ?? 'Información no disponible',
          currentPage: nextPage,
          isFirstPage: nextPage == 1,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void navigateToPreviousPage(
      BuildContext context, int previousPage, List<String> materials) {
    // Ajuste del índice para obtener el material correcto para la página anterior
    String materialKey = materials[previousPage - 1];
    String backgroundImagePath = materialInfo.containsKey(materialKey)
        ? materialInfo[materialKey]!
        : 'assets/images/default_image.png';
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReusableCountSplashScreen(
          backgroundImagePath: backgroundImagePath,
          currentPage: previousPage,
          isFirstPage: previousPage == 1,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyInicio(cameras: []),
      ),
    );
  }

  static Future<List<String>> getDistinctMaterials(String email) async {
    List<String> materials = [];

    try {
      // Realiza la consulta filtrando por el campo 'email' pasado como parámetro
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('historial')
          .where('email', isEqualTo: email) // Filtra por el email pasado
          // .orderBy('material') // Elimine temporalmente `orderBy` para ver si afecta los resultados
          .get();

      // Verifica si hay documentos en el snapshot
      debugPrint('Cantidad de documentos recuperados: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        debugPrint('No se encontraron documentos para el email proporcionado.');
      } else {
        // Extrae los valores únicos de la columna 'material'
        Set<String> uniqueMaterials =
            snapshot.docs.map((doc) => doc['item'] as String).toSet();

        materials = uniqueMaterials.toList();
      }
    } catch (e) {
      debugPrint('Error obteniendo materiales: $e');
    }

    return materials;
  }

  static Future<int> countMaterialInHistorial(
      String material, String email) async {
    int count = 0;
    try {
      // Realiza la consulta para contar los documentos del material y el email especificados
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('historial')
          .where('item', isEqualTo: material)
          .where('email', isEqualTo: email) // Filtra por el email pasado
          .get();

      // La cantidad de documentos en el snapshot representa la cantidad de registros
      count = snapshot.docs.length;
    } catch (e) {
      debugPrint('Error contando registros para el material $material: $e');
    }

    return count;
  }

  Future<String?> getCurrentUserEmail() async {
    try {
      // Obtiene el email del usuario actualmente autenticado
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      return userEmail;
    } catch (e) {
      debugPrint('Error obteniendo el email del usuario: $e');
      return null;
    }
  }

  static Future<void> exportToExcel(
    Map<String, int> residuos,
    Function(String) showSuccessMessage,
  ) async {
    try {
      // Crear archivo Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Resumen'];

      sheetObject.appendRow(['Item', 'Cantidad']);
      residuos.forEach((material, cantidad) {
        sheetObject.appendRow([material, cantidad]);
      });
      sheetObject.appendRow(['Total', residuos.values.reduce((a, b) => a + b)]);

      Uint8List? excelBytes = excel.save() as Uint8List?;
      if (excelBytes == null) {
        throw Exception('No se pudo generar el archivo Excel.');
      }

      // Obtener carpeta segura para descargas
      //final directory = await DownloadsPathProvider.downloadsDirectory;
      final directory = Directory('/storage/emulated/0/Download');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/resumen_reciclado_$timestamp.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(excelBytes);

      showSuccessMessage(
          '');
    } catch (e, stacktrace) {
      debugPrint('Error al guardar el archivo: $e\n$stacktrace');
      throw Exception('Error al guardar el archivo.');
    }
  }

  static String getMaterialIconPath(String material) {
    switch (material.toLowerCase()) {
      case 'plastico':
        return 'assets/icons/Plastico.png';
      case 'vidrio':
        return 'assets/icons/Vidrio.png';
      case 'papel':
        return 'assets/icons/Papel.png';
      case 'metal':
        return 'assets/icons/Metal.png';
      case 'aluminio':
        return 'assets/icons/Aluminio.png';
      case 'carton':
        return 'assets/icons/Carton.png';
      case 'isopor':
        return 'assets/icons/Isopor.png';
      default:
        return 'assets/icons/Residuos.png';
    }
  }

  static Future<void> showResiduoInfoModal(
      BuildContext context, String iconPath, String descripcion) async {
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return const Center(child: CircularProgressIndicator());
      },
    );

    String chatGptResponse;
    try {
      final String prompt =
          'Proporciona información breve sobre "$descripcion" y cómo reciclarlo.';
      chatGptResponse = await Funciones.getChatGPTResponse(prompt);
    } catch (e) {
      chatGptResponse = 'Error al obtener información: $e';
    }

    if (dialogContext != null) {
      Navigator.of(dialogContext!).pop();
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Image.asset(
                iconPath,
                width: 100,
                height: 100,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  descripcion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              chatGptResponse,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> exportToPDFWithChart(
    String conceptoHuella,
    String detallesInforme,
    Map<String, int> resumen,
    Uint8List chartImageBytes,
    Function(String) showSuccessMessage,
  ) async {
    try {
      // Verificar permisos con la función reutilizable
      bool permisoOk = await Funciones().verificarPermisosAlmacenamiento();
      if (!permisoOk) {
        throw Exception('Permiso de almacenamiento denegado');
      }
      // Crear PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Informe de Huella de Carbono',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  '¿Qué es la Huella de Carbono?',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(conceptoHuella,
                    style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Detalles del Informe',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(detallesInforme,
                    style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Gráfico de Resumen',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Image(
                  pw.MemoryImage(chartImageBytes),
                  width: 400,
                  height: 300,
                ),
              ],
            );
          },
        ),
      );

      // Ruta segura en Descargas (Android)
      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download');

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath =
            '${directory.path}/informe_huella_carbono_$timestamp.pdf';
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        showSuccessMessage(
            '');
      } else {
        // Otras plataformas (iOS, desktop)
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/informe_huella_carbono.pdf';
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        showSuccessMessage(
            'PDF guardado correctamente en la carpeta de Descargas');
      }
    } catch (e, stacktrace) {
      debugPrint('Error al guardar el archivo: $e\n$stacktrace');
      throw Exception('Error al guardar el archivo.');
    }
  }

  /// Obtiene una descripción de la huella de carbono utilizando IA.
  static Future<String> obtenerDescripcionHuella() async {
    const prompt = '''
      Explica brevemente qué es la huella de carbono de manera clara y comprensible para el usuario final.
      Actua como un experto en temas de cuidado ambiental y cambio climático
    ''';

    try {
      final respuestaIA = await getChatGPTResponse(prompt);
      return respuestaIA;
    } catch (e) {
      return 'Hubo un error al obtener la descripción de la huella de carbono: $e';
    }
  }

  /// Genera un informe del impacto en carbono basado en las unidades recicladas.
  static Future<String> generarInformeHuellaCarbono(
      Map<String, int> resumen) async {
    // Crea el prompt dinámico para enviar a la API
    final prompt = _crearPromptParaImpacto(resumen);

    try {
      // Envia el prompt a ChatGPT y obtiene la respuesta
      final respuestaIA = await getChatGPTResponse(prompt);

      // Parsear los resultados para obtener los porcentajes
      final impactos = _parsearImpactoRespuesta(respuestaIA);

      // Generar el informe
      final informe = impactos.entries.map((entry) {
        final material = entry.key;
        final porcentaje = entry.value;
        return '$material: ${porcentaje.toStringAsFixed(2)}% de carbono ahorrado.';
      }).join('\n');

      // Calcular el impacto total (promedio ponderado)
      final totalImpacto = _calcularImpactoTotal(resumen, impactos);

      return '''
      Detalles del Impacto de Carbono:
      $informe

      Impacto Total Estimado: ${totalImpacto.toStringAsFixed(2)}%
      ''';
    } catch (e) {
      return 'Hubo un error al generar el informe: $e';
    }
  }

  /// Crea el prompt para enviar a la API.
  static String _crearPromptParaImpacto(Map<String, int> resumen) {
    final materiales = resumen.entries.map((entry) {
      return '${entry.key}: ${entry.value} unidades recicladas';
    }).join(', ');

    return '''
      Con base en los datos proporcionados, calcula un porcentaje estimado de carbono ahorrado para cada material reciclado.
      También calcula un impacto total general considerando las cantidades de cada material.
      Datos:
      $materiales

      Devuelve los resultados en formato JSON donde las claves sean los materiales y los valores los porcentajes de carbono ahorrado.
    ''';
  }

  /// Parsea la respuesta de la API para extraer los porcentajes.
  static Map<String, double> _parsearImpactoRespuesta(String respuesta) {
    try {
      final Map<String, dynamic> jsonResponse = json.decode(respuesta);
      return jsonResponse
          .map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      // Intentar interpretar el texto como JSON manualmente
      final List<String> lineas = respuesta.split('\n');
      final Map<String, double> resultado = {};
      for (final linea in lineas) {
        final partes = linea.split(':');
        if (partes.length == 2) {
          final key = partes[0].trim();
          final value = double.tryParse(partes[1].trim());
          if (value != null) {
            resultado[key] = value;
          }
        }
      }
      if (resultado.isNotEmpty) {
        return resultado;
      }
      throw Exception('Error al parsear la respuesta: $e');
    }
  }

  /// Calcula el impacto total basado en los porcentajes individuales y las cantidades recicladas.
  static double _calcularImpactoTotal(
      Map<String, int> resumen, Map<String, double> impactos) {
    double totalImpacto = 0.0;
    int totalUnidades = 0;

    resumen.forEach((material, cantidad) {
      totalUnidades += cantidad;
      final porcentaje = impactos[material] ?? 0.0;
      totalImpacto += porcentaje * cantidad;
    });

    return totalUnidades > 0 ? totalImpacto / totalUnidades : 0.0;
  }

  static Future<bool> guardarFeedback({
    required String nombre,
    required String apellido,
    required String comentarios,
    required String emailUsuario,
    required String fecha,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'nombre': nombre,
        'apellido': apellido,
        'comentarios': comentarios,
        'emailUsuario': emailUsuario,
        'fecha': fecha,
      });
      return true;
    } catch (e) {
      debugPrint('Error al guardar feedback: $e');
      return false;
    }
  }

  /// Muestra un modal de ayuda reutilizable.
  static void mostrarModalDeAyuda({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    String textoBoton = 'Cerrar',
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(textoBoton),
            ),
          ],
        );
      },
    );
  }

  static Future<void> descargarPdf({
    required String titulo,
    required String contenido,
    required BuildContext context,
  }) async {
    try {
      // Verificar permisos con la función reutilizable
      bool permisoOk = await Funciones().verificarPermisosAlmacenamiento();
      if (!permisoOk) {
        throw Exception('Permiso de almacenamiento denegado');
      }

      // Crear el documento PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  contenido,
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ],
            );
          },
        ),
      );

      String filePath;

      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${directory.path}/$titulo-$timestamp.pdf';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$titulo.pdf';
      }

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
    } catch (e) {
      debugPrint('Error al guardar el PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el PDF: $e')),
      );
    }
  }

  Future<File> compressImage(File imageFile, {int quality = 75}) async {
    try {
      // Leer la imagen original como bytes
      final imageBytes = await imageFile.readAsBytes();

      // Decodificar la imagen usando el paquete `image`
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        throw Exception('No se pudo decodificar la imagen.');
      }

      // Guardar la imagen comprimida en un archivo temporal
      final tempDir = Directory.systemTemp;
      final compressedFile = File('${tempDir.path}/compressed_image.jpg');

      // Exportar la imagen con calidad ajustada
      await compressedFile.writeAsBytes(
        img.encodeJpg(decodedImage, quality: quality),
      );

      return compressedFile;
    } catch (e) {
      debugPrint('Error al comprimir la imagen: $e');
      throw Exception('Error al comprimir la imagen.');
    }
  }

  Future<ImageProvider?> compressNetworkImage(String imageUrl) async {
    try {
      // Descargar la imagen como bytes
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Decodificar y comprimir la imagen
        final decodedImage = img.decodeImage(response.bodyBytes);
        if (decodedImage != null) {
          final compressedBytes = img.encodeJpg(decodedImage, quality: 75);
          return MemoryImage(Uint8List.fromList(compressedBytes));
        }
      }
    } catch (e) {
      debugPrint('Error al comprimir la imagen de red: $e');
    }
    return null;
  }
}
