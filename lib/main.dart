import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:recila_me/widgets/reciclame_app.dart';
import 'clases/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

List<CameraDescription>? cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  var status = await Permission.camera.request();
  if (status.isGranted) {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        print('No se encontraron cámaras disponibles');
      }
    } catch (e) {
      print('Error al obtener cámaras: $e');
      cameras = [];
    }
  } else {
    print('Permiso de cámara denegado');
    cameras = [];
  }

  runApp(ReciclaMeApp(cameras: cameras));
}
