import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:recila_me/widgets/reciclame_app.dart';
import 'package:seq_logger/seq_logger.dart';
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
  if (!SeqLogger.initialized) {
    SeqLogger.init(
      url: "http://localhost:5341/#/events?range=1d", //"http://localhost:5341",
      apiKey: "g7byfn5mxxsGIUXAeUQf",
      batchSize: 50,
    );
  }
  runApp(ReciclaMeApp(cameras: cameras));
}
