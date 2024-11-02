import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum SnackBarType { error, confirmation }

void showCustomSnackBar(BuildContext context, String message, SnackBarType type,
    {durationInMilliseconds = 3000}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 50.0,
      left: 20.0,
      right: 20.0,
      child: Material(
        color: Colors.transparent,
        child: AnimatedSnackBar(message: message, type: type),
      ),
    ),
  );

  // Insertar el overlay
  overlay.insert(overlayEntry);

  // Remover el overlay después de la duración especificada
  Future.delayed(Duration(milliseconds: durationInMilliseconds), () {
    overlayEntry.remove();
  });
}

class AnimatedSnackBar extends StatefulWidget {
  final String message;
  final SnackBarType type;

  const AnimatedSnackBar(
      {super.key, required this.message, required this.type});

  @override
  // ignore: library_private_types_in_public_api
  _AnimatedSnackBarState createState() => _AnimatedSnackBarState();
}

class _AnimatedSnackBarState extends State<AnimatedSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Color backgroundColor;
  late IconData icon;

  @override
  void initState() {
    super.initState();

    // Definir el color y el icono basado en el tipo de SnackBar
    switch (widget.type) {
      case SnackBarType.error:
        backgroundColor = Colors.red;
        icon = FontAwesomeIcons.circleExclamation;
        break;
      case SnackBarType.confirmation:
        backgroundColor = Colors.green;
        icon = FontAwesomeIcons.circleCheck;
        break;
    }

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Empieza desde abajo de la pantalla
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            FaIcon(
              icon,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
