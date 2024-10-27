import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/widgets/inicio.dart';
import 'package:recila_me/widgets/itemDetailScreen.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
    'pilas, Gracias, gracias'
  ];

  static final logger = SeqHttpLogger.create(
    host:
        'http://192.168.100.16:43674', //'http://10.0.2.2:43674'para el emulador
    apiKey: dotenv.env['SEQ_LOGGER'],
    globalContext: {
      'App': 'ReciclaMe',
    },
  );
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
      await SeqLog('error', 'Error al cerrar sesión: $e');
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
    final apiKey = dotenv.env['OPENAI_API_KEY'];
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
      await SeqLog('error',
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
    final apiKey = dotenv.env['OPENAI_API_KEY'];
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
      await SeqLog(
          'error', 'Error al generar la imagen: ${response.statusCode}');
      return '';
    }
  }

  static SeqLogger? _logger;

  // Implementación del Singleton para el logger
  static Future<void> _initializeLogger() async {
    _logger ??= SeqHttpLogger.create(
      host: /*'http://192.168.100.16:43674',*/ 'http://10.0.2.2:43674',
      /*para el emulador*/
      apiKey: dotenv.env['SEQ_LOGGER'],
      globalContext: {
        'App': 'ReciclaMe',
      },
    );
  }

  // Función que registra los acontecimientos en el SEQ log
  static Future<void> SeqLog(String status, String message) async {
    try {
      await _initializeLogger(); // Asegura que el logger se inicialice solo una vez

      if (_logger == null) return;

      // Ejecutar la operación con timeout de 1 segundo
      await _logWithTimeout(status, message, const Duration(seconds: 3));
    } catch (e) {
      print('Se produjo un error al intentar acceder al SEQ $e');
    }
  }

// Función auxiliar que maneja el timeout
  static Future<void> _logWithTimeout(
      String status, String message, Duration timeout) async {
    try {
      // Convertir el string `status` a `SeqLogLevel`
      SeqLogLevel logLevel = _mapStringToSeqLogLevel(status);

      await _logger!.log(logLevel, message).timeout(timeout, onTimeout: () {
        print(
            'La conexión a SEQ ha sido cancelada después de ${timeout.inSeconds} segundos');
        return; // Cancelar la operación si el tiempo de espera excede
      });

      await Future(() async {
        switch (logLevel) {
          case SeqLogLevel.information:
          case SeqLogLevel.warning:
          case SeqLogLevel.error:
          case SeqLogLevel.debug:
            await _logger!.log(
              logLevel,
              message,
              null,
              {'Timestamp': DateTime.now().toUtc().toIso8601String()},
            );
            break;
          default:
            print('Nivel de log no reconocido');
        }

        await _logger!.flush();
      }).timeout(const Duration(seconds: 3)); // Timeout de 3 segundos
    } catch (e) {
      if (e is TimeoutException) {
        print(
            'El log de SEQ excedió el tiempo límite de 10 segundos y se abortó.');
      } else {
        print('Se produjo un error al registrar el log en SEQ: $e');
      }
    }
  }

// Función auxiliar para convertir un String a SeqLogLevel
  static SeqLogLevel _mapStringToSeqLogLevel(String status) {
    switch (status.toLowerCase()) {
      case 'information':
        return SeqLogLevel.information;
      case 'warning':
        return SeqLogLevel.warning;
      case 'error':
        return SeqLogLevel.error;
      case 'debug':
        return SeqLogLevel.debug;
      default:
        throw ArgumentError('Nivel de log no reconocido: $status');
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
      SeqLog('error',
          'Se ha producido un error al cargar los datos del usuario $e');
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
    required String? imageUrl, // Agregamos imageUrl como parámetro requerido
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

        // Asegurarse de que el imageUrl no sea nulo
        String finalImageUrl = imageUrl ?? 'assets/images/perfil.png';

        // Actualizar los datos del usuario incluyendo imageUrl
        bool result = await _firestoreService.updateUser(
          nombre,
          apellido,
          edad,
          direccion,
          ciudad,
          pais,
          telefono,
          correo,
          finalImageUrl, // Pasamos la URL de la imagen aquí
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al guardar los datos.')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Imagen de perfil actualizada correctamente')),
        );
      } catch (e) {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la imagen: $e')),
        );
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
      print(country);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('El país no está soportado para WhatsApp')),
        );
        return; // Si no hay código para el país, salir de la función
      }

      // Si el número no empieza con el código de país, agregarlo
      if (!phoneNumber.startsWith(countryCodes[country]!)) {
        phoneNumber = '${countryCodes[country]}${phoneNumber.substring(1)}';
      }

      // Definir el mensaje a enviar, incluyendo el enlace de la imagen
      String message = Uri.encodeComponent(
          '¡Hola, estoy interesado en la publicación con ID número $id. Título: $title. Aquí puedes ver la imagen: $imageUrl');

      // URL usando el esquema `https://wa.me/`
      final Uri whatsappWebUri =
          Uri.parse('https://wa.me/$phoneNumber?text=$message');

      // Verificar si se puede abrir WhatsApp mediante este esquema alternativo
      if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se pudo abrir WhatsApp con el esquema web. Asegúrate de que está instalado.')),
        );
      }
    } catch (e) {
      // Manejo de errores
      debugPrint('Error al intentar abrir WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al intentar abrir WhatsApp: $e')),
      );
    }
  }

  static Future<File?> pickImageFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      SeqLog('information', 'Imagen seleccionada: ${pickedImage.path}');
      return File(pickedImage.path); // Devolver el archivo seleccionado
    } else {
      // Mostrar SnackBar si no se selecciona imagen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionó ninguna imagen.')),
      );
      return null; // Devolver null si no se seleccionó ninguna imagen
    }
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior
            .floating, // Hace que el SnackBar "flote" en lugar de estar pegado a la parte inferior
        margin: const EdgeInsets.all(16), // Margen alrededor del SnackBar
        duration: const Duration(seconds: 3), // Duración de la animación
      ),
    );
  }

  // Función para mostrar el modal de reglas del juego
  void showGameRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reglas del Juego'),
          content: const Text(
              '1. Arrastra los residuos hacia el basurero correcto (Plástico, Papel, Orgánico, Vidrio o Materiales Peligrosos).\n'
              '2. Ganas puntos por cada residuo correctamente clasificado.\n'
              '3. Pierdes puntos por clasificaciones incorrectas.\n'
              '4. El tiempo es limitado, ¡intenta clasificar tantos residuos como puedas antes de que el tiempo se agote!\n5. Diviértete Aprendiendo!!'),
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
Map<String, dynamic> generarResiduoAleatorio(List<Map<String, dynamic>> residuos) {
  final random = Random();
  return residuos[random.nextInt(residuos.length)];
}

// Verifica la respuesta y retorna el puntaje actualizado y el estado de la verificación
int verificarRespuesta(String tipoBasurero, String residuoActual, int puntos) {
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
  
}
