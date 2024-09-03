import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/lottie_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NoticiasChatGPT extends StatefulWidget {
  @override
  _MyChatWidgetState createState() => _MyChatWidgetState();
}

class _MyChatWidgetState extends State<NoticiasChatGPT> {
  final Funciones funciones = Funciones();
  final TextEditingController _controller = TextEditingController();
  String chatResponse = '';
  String imageUrl = ''; // Variable para almacenar la URL de la imagen
  bool isLoading = false;

  final List<String> recyclingKeywords = [
    'reciclaje', 'reciclar', 'reutilizar', 'sostenible', 'medio ambiente', 
    'desperdicio', 'plástico', 'papel', 'vidrio', 'metal', 'residuos', 
    'compostaje', 'ecología', 'basura'
  ];

  bool _isRecyclingRelated(String prompt) {
    return recyclingKeywords.any((keyword) => prompt.toLowerCase().contains(keyword));
  }

  /*Future<void> _fetchChatGPTResponse(String prompt) async {
    if (!_isRecyclingRelated(prompt)) {
      setState(() {
        chatResponse = 'Oops! La consulta debe estar relacionada con el reciclaje.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      chatResponse = '';
      imageUrl = ''; // Resetear la URL de la imagen
    });

    try {
      String response = await funciones.getChatGPTResponse(prompt);
      setState(() {
        chatResponse = response;
      });

      // Buscar una imagen relacionada
      await _fetchImage(prompt);
      
    } catch (e) {
      setState(() {
        chatResponse = e.toString().contains('insufficient_quota')
            ? 'Error: Has excedido tu cuota actual. Por favor revisa tu plan y detalles de facturación.'
            : 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }*/
  Future<void> _fetchChatGPTResponse(String prompt) async {
    if (!_isRecyclingRelated(prompt)) {
      setState(() {
        chatResponse = 'Oops! La consulta debe estar relacionada con el reciclaje.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      chatResponse = '';
      imageUrl = ''; // Resetear la URL de la imagen
    });

    try {
      String response = await funciones.getChatGPTResponse(prompt);
      setState(() {
        chatResponse = response;
      });

      // Generar una imagen relacionada
      await _fetchGeneratedImage('$prompt . Representa gráficamente');
      
    } catch (e) {
      setState(() {
        chatResponse = e.toString().contains('insufficient_quota')
            ? 'Error: Has excedido tu cuota actual. Por favor revisa tu plan y detalles de facturación.'
            : 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> _fetchGeneratedImage(String prompt) async {
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
        'size': '640x480' // Tamaño de la imagen
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final imageUrlGenerated = data['data'][0]['url'];
      setState(() {
        imageUrl = imageUrlGenerated;
      });
    } else {
      print('Error al generar la imagen: ${response.statusCode}');
      setState(() {
        imageUrl = '';
      });
    }
  }


  /*Future<void> _fetchImage(String query) async {
    final apiKey = dotenv.env['UNPLASH_KEY'];
    final apiUrl = 'https://api.unsplash.com/search/photos?query=$query+illustration&client_id=$apiKey&content_filter=high';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('API Response: $data');  // Imprimir la respuesta completa
      final imageResults = data['results'];
      if (imageResults.isNotEmpty) {
        setState(() {
          imageUrl = imageResults[0]['urls']['regular'];
        });
      } else {
        setState(() {
          imageUrl = '';
        });
      }
    } else {
      print('Error al buscar la imagen: ${response.statusCode}');
      setState(() {
        imageUrl = '';
      });
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.green.shade200,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        title: const Text(
          'ChatGPT Response',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter prompt',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final prompt = _controller.text;
                if (prompt.isNotEmpty) {
                  _fetchChatGPTResponse(prompt);
                }
              },
              child: const Text('Enviar Consulta'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? buildLottieAnimation(
                      path: 'assets/animations/lotti-recycle.json',
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.contain,
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (imageUrl.isNotEmpty)
                            Image.network(imageUrl), // Mostrar la imagen
                          const SizedBox(height: 8),
                          Text(
                            chatResponse,
                            textAlign: TextAlign.justify,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
