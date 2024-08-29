import 'package:flutter/material.dart';
import 'package:recila_me/clases/funciones.dart';  // Asegúrate de importar la clase Funciones

class noticiasChatgpt extends StatefulWidget {
  @override
  _MyChatWidgetState createState() => _MyChatWidgetState();
}

class _MyChatWidgetState extends State<noticiasChatgpt> {
  final Funciones funciones = Funciones();  // Crear una instancia de Funciones
  final TextEditingController _controller = TextEditingController();  // Controlador para el TextField
  String chatResponse = '';

  void _fetchChatGPTResponse(String prompt) async {
    try {
      String response = await funciones.getChatGPTResponse(prompt);
      setState(() {
        chatResponse = response;
      });
    } catch (e) {
      if (e.toString().contains('insufficient_quota')) {
        setState(() {
          chatResponse = 'Error: Has excedido tu cuota actual. Por favor revisa tu plan y detalles de facturación.';
        });
      } else {
        setState(() {
          chatResponse = 'Error: $e';
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatGPT Response'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter prompt',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final prompt = _controller.text;
                if (prompt.isNotEmpty) {
                  _fetchChatGPTResponse(prompt);  // Llamar a getChatGPTResponse
                }
              },
              child: Text('Enviar Consulta'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(chatResponse),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
