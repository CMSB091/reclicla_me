import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/chatBuble.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';

class NoticiasChatGPT extends StatefulWidget {
  const NoticiasChatGPT({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyChatWidgetState createState() => _MyChatWidgetState();
}

class _MyChatWidgetState extends State<NoticiasChatGPT> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController _controller = TextEditingController();
  String chatResponse = '';
  String imageUrl = '';
  bool isLoading = false;
  List<Map<String, dynamic>> chatHistory = [];
  late String userEmail = 'Cargando...'; // valor por defecto
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;
  String typingIndicator =
      'Escribiendo'; // Texto inicial para el indicador de escritura
  // ignore: unused_field
  Timer? _typingTimer; // Timer para animación de "Escribiendo..."

  Future<void> _setUserEmail() async {
    String? email = await firestoreService.loadUserEmail();
    if (email!.isNotEmpty) {
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
        typingIndicator =
            'Escribiendo${'.' * dotCount}'; // Agrega puntos de manera cíclica
      });
    });
  }

  bool _isRecyclingRelated(String prompt) {
    return Funciones.recyclingKeywords
        .any((keyword) => prompt.toLowerCase().contains(keyword));
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
        chatResponse =
            'Lo siento, solo puedo responder a consultas relacionadas con el reciclaje de materiales comunes en el hogar y proporcionar ideas para reutilizarlos de manera creativa.';
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
      String finalPrompt =
          'Eres un experto en reciclaje de residuos comunes del hogar, incluyendo plásticos, metales, cartones, papeles, pilas y compostaje. Proporciona consejos prácticos y creativos sobre cómo reciclar o reutilizar estos materiales de manera sostenible en el hogar. Por favor, da la respuesta en no más de 200 palabras. Actua como si fueses una persona real y teniendo en cuenta lo siguiente: $prompt';
      String response = await Funciones.fetchChatGPTResponse(
          finalPrompt, _isRecyclingRelated(prompt));

      setState(() {
        isTyping = false;
        chatResponse = response;
        chatHistory.add({'message': response, 'isUser': false});
      });

      firestoreService.saveInteractionToFirestore(prompt, response, userEmail);
    } catch (e) {
      setState(() {
        isTyping = false;
        Funciones.SeqLog(
            'error',
            e.toString().contains('insufficient_quota')
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
      chatHistory.clear(); // Limpiar el historial actual
      if (chat['userPrompt'] != null && chat['chatResponse'] != null) {
        chatHistory.add({'message': chat['userPrompt'], 'isUser': true});
        chatHistory.add({'message': chat['chatResponse'], 'isUser': false});
      } else {
        Funciones.SeqLog(
            'error', 'Datos del chat seleccionados están incompletos');
      }
    });
  }

  Future<void> _showChatHistory() async {
    try {
      List<Map<String, dynamic>> chatHistoryList =
          await firestoreService.fetchChatHistoryByEmail(userEmail);

      if (chatHistoryList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se encontraron interacciones previas para este usuario.')),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Historial de Chat'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: chatHistoryList.length,
                    itemBuilder: (context, index) {
                      final chat = chatHistoryList[index];
                      return ListTile(
                        title: Text(chat['timestamp'] ?? 'Fecha no disponible'),
                        subtitle: Text(
                          chat['userPrompt'] ?? 'Prompt vacío',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(FontAwesomeIcons.trash,
                              color: Colors.red),
                          onPressed: () async {
                            // Confirmar eliminación
                            final confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Confirmar eliminación'),
                                  content: const Text(
                                      '¿Estás seguro de que quieres eliminar este chat?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmDelete == true) {
                              await firestoreService.deleteChatById(chat['id']);
                              setState(() {
                                chatHistoryList.removeAt(
                                    index); // Eliminar del historial local
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Chat eliminado.')),
                              );
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).pop(); // Cerrar el diálogo
                          _loadSelectedChat(
                              chat); // Cargar el chat seleccionado
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      Funciones.SeqLog('error', 'Error al recuperar el historial de chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el historial de chat.')),
      );
    }
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
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.clockRotateLeft,
                color: Colors.black),
            onPressed: () {
              _showChatHistory();
            },
          ),
        ],
      ),
      body: BlurredBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(10),
                itemCount: chatHistory.length + (isTyping ? 3 : 2),
                itemBuilder: (context, index) {
                  if (index == chatHistory.length + (isTyping ? 2 : 1)) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        '¡Hola! Soy Recyclops, aquí para ayudarte a reciclar de manera creativa y sostenible.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Artwork',
                            fontSize: 22,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  if (index == chatHistory.length + (isTyping ? 1 : 0)) {
                    return Center(
                      child: Lottie.asset(
                        'assets/animations/lottie-chat-bot.json',
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

                  final message = chatHistory[
                      chatHistory.length - 1 - (isTyping ? index - 1 : index)];
                  return ChatBubble(
                    message: message['message'] ?? 'Mensaje vacío',
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
                    icon: const Icon(FontAwesomeIcons.paperPlane,
                        color: Colors.green),
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
      ),
    );
  }
}
