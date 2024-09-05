import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:http/http.dart' as http; // Asegúrate de ajustar la ruta según tu estructura


class Funciones {

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
      print('Error al cerrar sesión: $e');
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
      print(prompt);
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      print('Error ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
      throw Exception('Failed to load ChatGPT response');
    }
  }

   Future<String> fetchChatGPTResponse(
      String prompt, bool isRecyclingRelated(String prompt)) async {
    if (!isRecyclingRelated(prompt)) {
      return 'Oops! La consulta debe estar relacionada con el reciclaje.';
    }

    try {
      String response = await getChatGPTResponse('$prompt. Dame la respuesta en 200 palabras');
      return response;
    } catch (e) {
      return e.toString().contains('insufficient_quota')
          ? 'Error: Has excedido tu cuota actual. Por favor revisa tu plan y detalles de facturación.'
          : 'Error: $e';
    }
  }

  Future<String> fetchGeneratedImage(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    final apiUrl = 'https://api.openai.com/v1/images/generations';

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
      print('Error al generar la imagen: ${response.statusCode}');
      return '';
    }
  }

}