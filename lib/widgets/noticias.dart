import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';

class NoticiasChatGPT extends StatefulWidget {
  const NoticiasChatGPT({super.key});

  @override
  _MyChatWidgetState createState() => _MyChatWidgetState();
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(10),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      decoration: BoxDecoration(
        color: isUser ? Colors.green[300] : Colors.grey[300],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomLeft: Radius.circular(isUser ? 15 : 0),
          bottomRight: Radius.circular(isUser ? 0 : 15),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isUser ? Colors.black : Colors.black87,
          fontStyle: message == '...' ? FontStyle.italic : FontStyle.normal, // Italic for typing indicator
        ),
      ),
    );
  }
}

class _MyChatWidgetState extends State<NoticiasChatGPT> {
  final Funciones funciones = Funciones();
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController _controller = TextEditingController();
  String chatResponse = '';
  String imageUrl = ''; // Variable para almacenar la URL de la imagen
  bool isLoading = false;
  List<Map<String, String>> chatHistory = [];
  late String userEmail;
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;
  String typingIndicator = '';

  Future<void> _setUserEmail() async {
    String? email = await firestoreService.loadUserEmail();
    setState(() {
      userEmail = email!;
    });
  }

  Timer? _typingTimer;

  void _startTypingAnimation() {
    setState(() {
      isTyping = true;
      typingIndicator = '';
    });

    int count = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        count = (count + 1) % 4;
        typingIndicator = '.' * count;
      });
    });
  }

  void _stopTypingAnimation() {
    _typingTimer?.cancel();
    setState(() {
      isTyping = false;
      typingIndicator = '';
    });
  }

  final List<String> recyclingKeywords = [
  'reciclaje', 'reciclar', 'reutilizar', 'sostenible', 'casa', 'hogar', 
  'materiales', 'botella', 'plástico', 'papel', 'cartón', 'vidrio', 
  'lata', 'metal', 'residuos', 'desechos', 'decoración', 'manualidades', 
  'ecología', 'basura', 'compostaje'
  ];

  bool _isRecyclingRelated(String prompt) {
    return recyclingKeywords.any((keyword) => prompt.toLowerCase().contains(keyword));
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
        return;
      });
    }

    setState(() {
      isLoading = true;
      chatResponse = '';
      imageUrl = ''; // Reset image URL
    });

    _startTypingAnimation(); // Start typing animation

    try {
      String finalPrompt = 'Eres un experto en reciclaje creativo enfocado en materiales comunes del hogar como plástico, papel, cartón, vidrio, y metal. Proporciona ideas prácticas para reutilizar estos materiales en objetos útiles o decorativos con materiales simples que se tienen en el hogar, necesito que ajustes la respuesta en 200 palabras. Consulta:\n\n$prompt';

      String response = await funciones.fetchChatGPTResponse(finalPrompt, _isRecyclingRelated(prompt));

      setState(() {
        chatResponse = response;
        chatHistory.add({'user': prompt, 'bot': chatResponse});
      });

      String imagePrompt = funciones.generateImagePromptFromResponse(response);
      imageUrl = await funciones.fetchGeneratedImage(imagePrompt);
      setState(() {});

      // Save interaction to Firestore
      firestoreService.saveInteractionToFirestore(prompt, response,userEmail);

    } catch (e) {
      setState(() {
        chatResponse = e.toString().contains('insufficient_quota')
            ? 'Error: Has excedido tu cuota actual. Por favor revisa tu plan y detalles de facturación.'
            : 'Error: $e';
        chatHistory.add({'user': prompt, 'bot': chatResponse});
      });

      // Save interaction to Firestore
      firestoreService.saveInteractionToFirestore(prompt, chatResponse,userEmail);

    } finally {
      _stopTypingAnimation(); // Stop typing animation
      setState(() {
        isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  void initState() {
    super.initState();
    _setUserEmail(); // Call the function to set the user's email
  }

  Future<List<Map<String, dynamic>>> fetchChatHistoryByEmail(String email) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('chat_interactions')
        .where('userEmail', isEqualTo: email)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'userPrompt': doc['userPrompt'] ?? '',
        'chatResponse': doc['chatResponse'] ?? '',
        'timestamp': doc['timestamp']?.toDate().toString() ?? '',
      };
    }).toList();
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
    if (userEmail == null) return; // Ensure the email is available

    List<Map<String, dynamic>> chatHistoryList = await fetchChatHistoryByEmail(userEmail!);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chat History'),
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
          Text('ChatBot', style: TextStyle(color: Colors.black)),
          if (userEmail != null)
            Text(
              'Logged in as: $userEmail',
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.history, color: Colors.black),
          onPressed: () {
            _showChatHistory(); // Open chat history when tapped
          },
        ),
      ],
    ),
      body: Column(
        children: [
          // Chat messages display
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(10),
              itemCount: chatHistory.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == 0) {
                  // Show typing animation at the end of the list
                  return ChatBubble(
                    message: typingIndicator,
                    isUser: false,
                  );
                }
                
                final message = chatHistory[chatHistory.length - 1 - (isTyping ? index - 1 : index)];
                return ChatBubble(
                  message: message['bot'] ?? message['user']!,
                  isUser: message['user'] != null,
                );
              },
            ),
          ),
          // Input field and send button
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
                        chatHistory.add({'user': prompt});
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


