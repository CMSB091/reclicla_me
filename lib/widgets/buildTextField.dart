// Este es un widget para todos los campos de tipo texField y numberField
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    required String labelText,
    required TextEditingController controller,
    required int maxLength,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool isReadOnly = false
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          decoration: buildInputDecoration(labelText),
          validator: validator,
          maxLines: null,
          keyboardType: keyboardType,
          inputFormatters:
              inputFormatters ?? [LengthLimitingTextInputFormatter(maxLength)],
          readOnly: isReadOnly
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              '${controller.text.length}/$maxLength',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }