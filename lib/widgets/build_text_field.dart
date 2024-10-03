// Este es un widget para todos los campos de tipo texField y numberField
import 'package:flutter/material.dart';

  InputDecoration buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: Colors.black, // Color del label
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.1), // Fondo oscuro para el campo
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: Colors.black, // Borde oscuro
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: Colors.green, // Borde cuando el campo está enfocado
        ),
      ),
    );
  }

Widget buildTextField({
  required TextEditingController controller,
  required String labelText,
  bool isNumber = false,
  bool isReadOnly = false,
  VoidCallback? onTap,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      onTap: onTap,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: buildInputDecoration(labelText), // Usar la función aquí
      style: const TextStyle(
        color: Colors.black, // Color del texto dentro del campo
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa tu $labelText';
        }
        return null;
      },
    ),
  );
}