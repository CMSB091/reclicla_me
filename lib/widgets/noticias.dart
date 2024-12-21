import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/buildTextField.dart';
import 'package:recila_me/widgets/chatBuble.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/historialPage.dart';

class NoticiasChatGPT extends StatefulWidget {
  final String initialPrompt;
  final String detectedObject;

  // ignore: use_super_parameters
  const NoticiasChatGPT(
      {Key? key, required this.initialPrompt, required this.detectedObject})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyChatWidgetState createState() => _MyChatWidgetState();
}

class _MyChatWidgetState extends State<NoticiasChatGPT> {
  final FirestoreService firestoreService = FirestoreService();
  TextEditingController _controller = TextEditingController();
  String chatResponse = '';
  String imageUrl = '';
  bool isLoading = false;
  List<Map<String, dynamic>> chatHistory = [];
  String userEmail = 'Cargando...';
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;
  String typingIndicator = 'Escribiendo';
  Timer? _typingTimer;
  bool isFirstMessage = true;
  late String initialPrompt;

  Future<void> _setUserEmail() async {
    try {
      String? email = await firestoreService.loadUserEmail();
      setState(() {
        userEmail = email ?? 'Correo no disponible';
      });
    } catch (e) {
      setState(() {
        userEmail = 'Error al cargar el correo';
      });
      debugPrint('Error al cargar el correo del usuario: $e');
    }
  }

  Future<void> _saveRecommendation() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistorialPage(
          detectedItem: widget.detectedObject,
          initialDescription: chatResponse.trim(),
        ),
      ),
    );
  }

  void mostrarAyudaGeneral(BuildContext context) {
      Funciones.mostrarModalDeAyuda(
        context: context,
        titulo: 'Ayuda',
        mensaje:
            'Escribe una consulta al chatBot especializado en reciclaje.\n'
            'Si tienes dudas específicas, consulta las secciones correspondientes.',
        textoBoton: 'Entendido',
      );
    }

  void _startTypingAnimation() {
    setState(() {
      isTyping = true;
    });

    int dotCount = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4;
        typingIndicator = 'Escribiendo${'.' * dotCount}';
      });
    });
  }

  bool _isRecyclingRelated(String prompt) {
    return Funciones.recyclingKeywords
        .any((keyword) => prompt.toLowerCase().contains(keyword));
  }

  void _scrollToBottom() {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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

    // Construye el historial de conversación en un solo string
    String conversationContext = chatHistory
        .map((message) =>
            (message['isUser'] ? "Tú: " : "Chatbot: ") + message['message'])
        .join("\n");

    // Construye el prompt con el contexto de la conversación
    String finalPrompt = isFirstMessage
        ? 'Eres un experto en reciclaje de residuos comunes del hogar, incluyendo plásticos, metales, cartones, papeles, pilas y compostaje. Proporciona consejos prácticos y creativos sobre cómo reciclar o reutilizar estos materiales de manera sostenible en el hogar. Por favor, da la respuesta en no más de 200 palabras. Actúa como si fueses una persona real y teniendo en cuenta lo siguiente:\n\n$conversationContext\nTú: $prompt'
        : '$conversationContext\nTú: $prompt';

    try {
      String response = await Funciones.fetchChatGPTResponse(
          finalPrompt, _isRecyclingRelated(prompt));

      setState(() {
        isTyping = false;
        chatResponse = response;
        chatHistory.add({'message': response, 'isUser': false});
        isFirstMessage = false;
      });

      firestoreService.saveInteractionToFirestore(prompt, response, userEmail);
    } catch (e) {
      debugPrint('Error al obtener respuesta: $e');
      await Funciones.saveDebugInfo(e.toString().contains('insufficient_quota')
          ? 'Error: Has excedido tu cuota actual. Por favor revisa tu plan y detalles de facturación.'
          : 'Error: $e');
      setState(() {
        isTyping = false;
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

    // Inicializa _controller con el texto inicial de initialPrompt
    _controller = TextEditingController(
        text: widget.initialPrompt.isNotEmpty ? widget.initialPrompt : "");

    // Configura el listener para actualizar el contador de caracteres al inicio
    _controller.addListener(() {
      setState(
          () {}); // Esto forzará la actualización del contador de caracteres
    });
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
            icon:
                // ignore: deprecated_member_use
                const FaIcon(FontAwesomeIcons.infoCircle, color: Colors.black),
            onPressed: () {
               mostrarAyudaGeneral(context);
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
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: chatHistory.length + (isTyping ? 3 : 2),
                itemBuilder: (context, index) {
                  if (index == chatHistory.length + (isTyping ? 2 : 1)) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        '¡Hola! Soy Recyclops, estoy aquí para ayudarte a reciclar de manera creativa y sostenible.',
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
            if (chatResponse
                .isNotEmpty) // Muestra el botón solo si hay una respuesta del chat
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _saveRecommendation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    'Guardar Recomendación',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      labelText: '',
                      controller: _controller,
                      maxLength: 200,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Debe ingresar un mensaje'
                          : null,
                      hint: 'Escribe un mensaje...',
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
                          _fetchChatGPTResponse(prompt);
                          _controller.clear();
                        });
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

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
