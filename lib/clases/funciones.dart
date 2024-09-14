import 'dart:convert';
import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:http/http.dart' as http; // Asegúrate de ajustar la ruta según tu estructura


class Funciones {

  final FirestoreService firestoreService = FirestoreService();
  final List<String> recyclingKeywords = [
  'reciclaje', 'reciclar', 'reutilizar', 'sostenible', 'casa', 'hogar', 
  'materiales', 'botella', 'plástico', 'papel', 'cartón', 'vidrio', 
  'lata', 'metal', 'residuos', 'desechos', 'decoración', 'manualidades', 
  'ecología', 'basura', 'compostaje','pila','pilas'
  ];

  String generateImagePromptFromResponse(String chatGPTResponse) {
    // Aquí puedes aplicar lógica para extraer una idea clave de la respuesta.
    // En este ejemplo, simplemente extraemos palabras clave relacionadas con reciclaje.
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
  Future<void> simulateLogout(BuildContext context) async {
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
      await log('error','Error al cerrar sesión: $e');
    } finally {
      // Cierra el diálogo
      Navigator.of(context, rootNavigator: true).pop();
      // Redirige a la página de login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginApp(),
        ),
      );
    }  
  }

  Future<String> getChatGPTResponse(String prompt) async {
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
        'max_tokens': 200,
      })),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      await log('error','Error ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
      throw Exception('Failed to load ChatGPT response');
    }
  }

  
    Future<String> fetchChatGPTResponse(String prompt, bool isRecyclingRelated) async {
    // Fetch recent interactions for context
    List<Map<String, String>> recentInteractions = await firestoreService.fetchInteractionsFromFirestore();

    // Build a context string from recent interactions
    String context = recentInteractions.map((interaction) {
      return 'User: ${interaction['userPrompt']}\nBot: ${interaction['chatResponse']}';
    }).join('\n\n');

    // Combine context with the new prompt
    String finalPrompt = '$context\n\nUser: $prompt\nBot:';

    // Call the ChatGPT API with the finalPrompt
    if(isRecyclingRelated){
          String response = await getChatGPTResponse(finalPrompt);
      return response;
    }else{
      return 'Por favor, realiza una consulta relacionada con el reciclaje de materiales en el hogar y cómo reutilizarlos de manera creativa.';
    }

  }

  Future<String> fetchGeneratedImage(String prompt) async {
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
      await log('error','Error al generar la imagen: ${response.statusCode}');
      return '';
    }
  }

  Future<void> log(String status, message) async {
    try{
      final logger = SeqHttpLogger.create(
        host: /*'http://192.168.100.16:43674',*/'http://10.0.2.2:43674', /*para el emulador*/
        apiKey: dotenv.env['OPENAI_API_KEY'],
        globalContext: {
          'App': 'ReciclaMe',
        },
      );
      if(status == 'information'){
      await logger.log(
        SeqLogLevel.information,
        message,
        null,
        {
          'Timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }else if (status == 'warning'){
    await logger.log(
        SeqLogLevel.warning,
        message,
        null,
        {
          'Timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }else if (status == 'error'){
      await logger.log(
        SeqLogLevel.error,
        message,
        null,
        {
          'Timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }else if(status == 'debug'){
      await logger.log(
        SeqLogLevel.debug,
        message,
        null,
        {
          'Timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }
    await logger.flush();
    }catch(e){
      print('Se produjo un error al intentar acceder al SEQ $e');
    }
  }
  

}