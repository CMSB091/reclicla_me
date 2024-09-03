import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:recila_me/widgets/login.dart';
import 'package:http/http.dart' as http;

class Funciones {
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
        'max_tokens': 800,
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

  

}