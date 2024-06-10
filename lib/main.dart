import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:recila_me/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recicla Me',
      theme: ThemeData(
        primaryColor: Colors.green.shade200,
        hintColor: Colors.green.shade300,
        fontFamily: 'Roboto',
      ),
      home: LoginApp(),
    );
  }
}
