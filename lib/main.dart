import 'package:flutter/material.dart';
import 'package:recila_me/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recila Me',
      theme: ThemeData(
        primaryColor: Colors.green.shade200, // Color principal
        hintColor: Colors.green.shade300, // Color de acento
        fontFamily: 'Roboto', // Fuente predeterminada
      ),
      home: LoginApp(),
    );
  }
}
