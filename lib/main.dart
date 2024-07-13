import 'package:firebase_core/firebase_core.dart';
import 'package:recila_me/widgets/reciclame_app.dart';
import 'clases/firebase_options.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ReciclaMeApp());
}