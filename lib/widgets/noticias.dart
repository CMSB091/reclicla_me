import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/chatBuble.dart';

class NoticiasChatGPT extends StatefulWidget {
  const NoticiasChatGPT({super.key});

  @override
  _MyChatWidgetState createState() => _MyChatWidgetState();
}

class _MyChatWidgetState extends State<NoticiasChatGPT> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController _controller = TextEditingController();
  String chatResponse = '';
  String imageUrl = '';
  bool isLoading = false;
  List<Map<String, dynamic>> chatHistory = [];
  late String userEmail = 'Cargando...'; // Inicializamos con un valor por defecto
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;
  String typingIndicator = 'Escribiendo'; // Texto inicial para el indicador de escritura
  Timer? _typingTimer; // Timer para animación de "Escribiendo..."

  Future<void> _setUserEmail() async {
    String? email = await firestoreService.loadUserEmail();
    if (email != null && email.isNotEmpty) {
      setState(() {
        userEmail = email;
      });
    } else {
      setState(() {
        Funciones.SeqLog('information', 'Correo no disponible');
        userEmail = 'Correo no disponible';
      });
    }
  }

  void _startTypingAnimation() {
    setState(() {
      isTyping = true;
    });

    int dotCount = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4; // Ciclo entre 0, 1, 2, 3
        typingIndicator = 'Escribiendo${'.' * dotCount}'; // Agrega puntos de manera cíclica
      });
    });
  }

  bool _isRecyclingRelated(String prompt) {
    return Funciones.recyclingKeywords.any((keyword) => prompt.toLowerCase().contains(keyword));
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _fetchChatGPTResponse(String prompt) async {
    if (!_isRecyclingRelated(prompt)) {
      setState(() {
        chatResponse = 'Lo siento, solo puedo responder a consultas relacionadas con el reciclaje de materiales comunes en el hogar y proporcionar ideas para reutilizarlos de manera creativa.';
        chatHistory.add({'message': chatResponse, 'isUser': false});
        isTyping = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      chatResponse = '';
      imageUrl = '';
      isTyping = true;
      _startTypingAnimation();
    });

    _startTypingAnimation();

    try {
      String finalPrompt = 'Eres un experto en reciclaje de residuos comunes del hogar, incluyendo plásticos, metales, cartones, papeles, pilas y compostaje. Proporciona consejos prácticos y creativos sobre cómo reciclar o reutilizar estos materiales de manera sostenible en el hogar. Por favor, da la respuesta en no más de 200 palabras teniendo en cuenta lo siguiente: $prompt';
      String response = await Funciones.fetchChatGPTResponse(finalPrompt, _isRecyclingRelated(prompt));
      
      setState(() {
        isTyping = false;
        chatResponse = response;
        chatHistory.add({'message': response, 'isUser': false});
      });

      firestoreService.saveInteractionToFirestore(prompt, response, userEmail);
    } catch (e) {
      setState(() {
        isTyping = false;
        Funciones.SeqLog('error', e.toString().contains('insufficient_quota')
            ? 'Error: Has excedido tu cuota actual. Por favor revisa tu plan y detalles de facturación.'
            : 'Error: $e');
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  void initState() {
    super.initState();
    _setUserEmail();
  }

  void _loadSelectedChat(Map<String, dynamic> chat) {
    setState(() {
      chatHistory.clear(); // Clear the current chat history
      chatHistory.add({
        'user': chat['userPrompt'],
        'bot': chat['chatResponse'],
      });
      chatResponse = chat['chatResponse']; // Display the selected chat's response
    });
  }

  Future<void> _showChatHistory() async {
    List<Map<String, dynamic>> chatHistoryList = await firestoreService.fetchChatHistoryByEmail(userEmail);

    if (chatHistoryList.isEmpty) {
      // If no chat history is found, display a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron interacciones previas para este usuario.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chat History'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: chatHistoryList.length,
              itemBuilder: (context, index) {
                final chat = chatHistoryList[index];
                return ListTile(
                  title: Text(chat['timestamp'] ?? 'No Date'),
                  subtitle: Text(
                    chat['userPrompt'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _loadSelectedChat(chat); // Load the selected chat
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade200,
        title: Column(
          children: [
            const Text('ChatBot', style: TextStyle(color: Colors.black)),
            Text(
              'Logged in as: $userEmail',
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () {
              _showChatHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(10),
              itemCount: chatHistory.length + (isTyping ? 3 : 2), // Include typing indicator, intro text, and Lottie animation
              itemBuilder: (context, index) {
                if (index == chatHistory.length + (isTyping ? 2 : 1)) {
                  // Show the introductory text
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Text(
                      '¡Hola, Mi nombre es Recyclops! Estoy aquí para ayudarte a encontrar formas creativas y sostenibles de reciclar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Artwork',
                        fontSize: 22, color: Colors.black54),
                    ),
                  );
                }

                if (index == chatHistory.length + (isTyping ? 1 : 0)) {
                  // Show Lottie animation
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/lottie-chat-bot.json', // Replace with your Lottie file path
                      width: 500,
                      height: 500,
                      repeat: true,
                    ),
                  );
                }

                if (isTyping && index == 0) {
                  return ChatBubble(
                    message: typingIndicator,
                    isUser: false,
                  );
                }

                final message = chatHistory[chatHistory.length - 1 - (isTyping ? index - 1 : index)];
                return ChatBubble(
                  message: message['message']!,
                  isUser: message['isUser'] as bool,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () {
                    final prompt = _controller.text;
                    if (prompt.isNotEmpty) {
                      setState(() {
                        chatHistory.add({'message': prompt, 'isUser': true});
                      });
                      _fetchChatGPTResponse(prompt);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
