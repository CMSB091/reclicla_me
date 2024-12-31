import 'dart:ui';
import 'package:flutter/material.dart';

class BlurredBackground extends StatelessWidget {
  final Widget child; // El contenido que estará encima del fondo
  final String imagePath;
  final double blurStrength;
  final double opacity;

  const BlurredBackground({
    super.key,
    required this.child,  // El widget hijo que se coloca sobre el fondo
    this.imagePath = 'assets/images/verdeFondo.jpg',  // Imagen predeterminada de fondo
    this.blurStrength = 1.0,  // Nivel de desenfoque predeterminado
    this.opacity = 0.1,  // Opacidad predeterminada de la capa sobre el fondo
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imagen de fondo
        Positioned.fill(
          child: Image.asset(
            imagePath, // Ruta de la imagen
            fit: BoxFit.cover, // Asegura que cubra toda la pantalla
          ),
        ),
        // Filtro de desenfoque
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength), // Se aplica la propiedad blur
            child: Container(
              color: Colors.black.withOpacity(opacity), // Color semitransparente
            ),
          ),
        ),
        // Contenido encima del fondo difuminado
        Positioned.fill(child: child),
      ],
    );
  }
}
