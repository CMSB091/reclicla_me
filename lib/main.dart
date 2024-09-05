import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  try {
    await dotenv.load(fileName: '.env');
    print('Variables de entorno cargadas correctamente');
  } catch (e) {
    print('Error al cargar el archivo .env: $e');
  }
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
      url: 'http://10.0.2.2:8080',//"http://localhost:5341", //"http://localhost:5341",
      apiKey: dotenv.env['SEQ_LOGGER'],
      batchSize: 1,
    );
    /* para dispositivos fisicos
    SeqLogger.init(
  url: 'http://192.168.1.100:8080', // IP de tu máquina local
  apiKey: dotenv.env['SEQ_LOGGER'],
  batchSize: 1,
  );
*/

    /*SeqLogger.log(
      level: SeqLogLevel.warning,
      message: 'Este es un mensaje de advertencia',
      properties: {
        'AppName': 'MiApp',
        'Version': '1.0.0',
      },
    );
    SeqLogger.flush();*/
    try {
      SeqLogger.logWarning(message: 'Este es un mensaje de advertencia');
      SeqLogger.logError(message: 'Este es un mensaje de error');
    } catch (e) {
      print('Error al enviar el log: $e');
    }
  }
  runApp(ReciclaMeApp(cameras: cameras));
}
