import 'package:flutter/material.dart';
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.of(context).size.width * 0.7;
    final Color bubbleColor = isUser ? Colors.green[300]! : Colors.grey[200]!;
    final BorderRadius bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(15),
      topRight: const Radius.circular(15),
      bottomLeft: Radius.circular(isUser ? 15 : 0),
      bottomRight: Radius.circular(isUser ? 0 : 15),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: bubbleRadius,
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.black : Colors.black87,
            fontStyle: FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
