import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/reciclame_app.dart';
import 'clases/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

List<CameraDescription>? cameras;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final Funciones funciones = Funciones();
  try {
    await dotenv.load(fileName: '.env');
    await funciones.log('debug','Variables de entorno cargadas correctamente');
  } catch (e) {
    await funciones.log('error','Error al cargar el archivo .env: $e');
  }
  var status = await Permission.camera.request();
  if (status.isGranted) {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        await funciones.log('debug','No se encontraron cámaras disponibles');
      }
    } catch (e) {
      await funciones.log('error','Error al obtener cámaras: $e');
      cameras = [];
    }
  } else {
    await funciones.log('debug','Permiso de cámara denegado');
    cameras = [];
  }
  runApp(ReciclaMeApp(cameras: cameras));
}
