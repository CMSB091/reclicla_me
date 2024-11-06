import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/reciclameApp.dart';
import 'clases/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

List<CameraDescription>? cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Solicitar permisos de cámara
  var status = await Permission.camera.request();
  if (status.isGranted) {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        Funciones.SeqLog('debug', 'No se encontraron cámaras disponibles');
      }
    } catch (e) {
      Funciones.SeqLog('error', 'Error al obtener cámaras: $e');
      cameras = [];
    }
  } else {
    Funciones.SeqLog('debug', 'Permiso de cámara denegado');
    cameras = [];
  }

  runApp(ReciclaMeApp(cameras: cameras));
}
