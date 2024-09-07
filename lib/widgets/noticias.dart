import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/lottie_widget.dart';

class NoticiasChatGPT extends StatefulWidget {
  const NoticiasChatGPT({super.key});

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

  Future<void> _fetchChatGPTResponse(String prompt) async {
    await funciones.log('debug','Prueba desde el celular fisico');
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
      String response =
          await funciones.fetchChatGPTResponse(prompt, _isRecyclingRelated);
      setState(() {
        chatResponse = response;
      });

      // Genera el prompt basado en la respuesta de ChatGPT
    String imagePrompt = funciones.generateImagePromptFromResponse(response);

      // Generar una imagen relacionada
      imageUrl = await funciones.fetchGeneratedImage(imagePrompt);
      setState(() {});
      
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
                      path: 'assets/animations/lotti-trash-2.json',
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.contain,
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (imageUrl.isNotEmpty)
                            SizedBox(
                              width: 312, // Establece el ancho deseado
                              height: 312, // Establece la altura deseada
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain, // Ajusta la imagen dentro del contenedor sin recortarla
                              ),
                            ),// Mostrar la imagen
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
