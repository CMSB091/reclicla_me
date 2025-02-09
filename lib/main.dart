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

  // Solicitar permisos necesarios
  await _requestPermissions();

  runApp(ReciclaMeApp(cameras: cameras));
}

Future<void> _requestPermissions() async {
  // Solicitar permisos de cámara y almacenamiento
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.storage, // Para Android versiones anteriores a Android 10
    Permission.photos,  // Para iOS
    Permission.manageExternalStorage, // Para acceso completo a archivos en Android 10+
  ].request();

  // Verificar si la cámara está permitida antes de inicializarla
  if (statuses[Permission.camera] == PermissionStatus.granted) {
    try {
      cameras = await availableCameras();
    } catch (e) {
      await Funciones.saveDebugInfo('Error al obtener cámaras: $e');
      cameras = [];
    }
  } else {
    cameras = [];
  }

  // Manejar permisos denegados
  if (statuses[Permission.storage] == PermissionStatus.denied ||
      statuses[Permission.manageExternalStorage] == PermissionStatus.denied ||
      statuses[Permission.photos] == PermissionStatus.denied) {
    await Funciones.saveDebugInfo(
        'El usuario denegó el acceso a los archivos.');
  }

  // Si el usuario seleccionó "No preguntar más", abrir configuración
  if (statuses[Permission.storage] == PermissionStatus.permanentlyDenied ||
      statuses[Permission.manageExternalStorage] == PermissionStatus.permanentlyDenied ||
      statuses[Permission.photos] == PermissionStatus.permanentlyDenied) {
    await openAppSettings();
  }
}
