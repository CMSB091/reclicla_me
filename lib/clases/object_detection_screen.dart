import 'dart:typed_data';  // Para Uint8List
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as image_lib;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ObjectDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ObjectDetectionScreen({super.key, required this.cameras});

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late CameraController _controller;
  Interpreter? _interpreter;
  bool _isDetecting = false;
  String _detectionResult = "Cargando modelo...";
  String _modelStatus = "Modelo no cargado";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  void _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _detectionResult = "No hay cámaras disponibles.";
      });
      return;
    }

    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {});
      }

      _controller.startImageStream((CameraImage img) {
        if (!_isDetecting && _interpreter != null) {
          _isDetecting = true;
          _runModelOnFrame(img);
        }
      });
    } catch (e) {
      setState(() {
        _detectionResult = "Error al inicializar la cámara: $e";
      });
    }
  }

  Future<void> _loadModel() async {
    try {
      Funciones.SeqLog('information',"Intentando cargar el modelo...");
      _interpreter = await Interpreter.fromAsset('assets/tflite/model.tflite');
      Funciones.SeqLog("information","Modelo cargado correctamente");
      if (mounted) {
        setState(() {
          _modelStatus = "Modelo cargado correctamente";
          _detectionResult = "Modelo cargado. Esperando detecciones...";
        });
      }
    } catch (e) {
      Funciones.SeqLog("error","Error al cargar el modelo: $e");
      if (mounted) {
        setState(() {
          _modelStatus = "Error al cargar el modelo.";
          _detectionResult = "Error al cargar el modelo.";
        });
      }
    }
  }

  void _runModelOnFrame(CameraImage img) async {
  if (_interpreter == null || _isDetecting) return;

  try {
    // Prevenimos múltiples ejecuciones concurrentes.
    _isDetecting = true;

    // Preprocesamos la imagen.
    final input = _preprocessImage(img);

    // Definimos la salida del modelo.
    final output = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]);

    // Ejecutamos el modelo.
    _interpreter!.run(input, output);
    
    setState(() {
      _detectionResult = "Detección completa. Resultados: ${output.first}";
      _saveImage(input);  // Guarda la imagen procesada
    });
  } catch (e) {
    Funciones.SeqLog("error","Error durante la detección: $e");
    setState(() {
      _detectionResult = "Error durante la detección: $e";
    });
  } finally {
    _isDetecting = false;
  }
}

  Uint8List _preprocessImage(CameraImage img) {
    final imageLibImage = _convertYUV420ToImage(img);

    // Redimensionar la imagen a 224x224 píxeles
    final resizedImage = image_lib.copyResize(imageLibImage, width: 224, height: 224);

    // Convertir la imagen a un buffer de bytes
    final buffer = Uint8List(224 * 224 * 3);
    int bufferIndex = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);

        // Convierte los valores a int explícitamente
        buffer[bufferIndex++] = pixel.r.toInt(); // Rojo
        buffer[bufferIndex++] = pixel.g.toInt(); // Verde
        buffer[bufferIndex++] = pixel.b.toInt(); // Azul
      }
    }

    return buffer;
  }

  image_lib.Image _convertYUV420ToImage(CameraImage img) {
    final int width = img.width;
    final int height = img.height;
    
    // Crea la imagen con el tamaño correcto
    final image_lib.Image image = image_lib.Image(width: width, height: height);

    Plane planeY = img.planes[0];
    Plane planeU = img.planes[1];
    Plane planeV = img.planes[2];

    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        final int yIndex = h * planeY.bytesPerRow + w;
        final int uvIndex = (h >> 1) * planeU.bytesPerRow + (w >> 1);

        final int y = planeY.bytes[yIndex];
        final int u = planeU.bytes[uvIndex];
        final int v = planeV.bytes[uvIndex];

        int r = (y + (v * 1.370705)).toInt();
        int g = (y - (u * 0.337633) - (v * 0.698001)).toInt();
        int b = (y + (u * 1.732446)).toInt();

        // Coloca el píxel en la imagen
        image.setPixelRgba(w, h, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255), 255);
      }
    }
    return image;
  }

  Future<void> _saveImage(Uint8List input) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/detected_image.png';
      final file = File(imagePath);
      await file.writeAsBytes(input);
      Funciones.SeqLog('information',"Imagen guardada en: $imagePath");
    } catch (e) {
      Funciones.SeqLog("error","Error al guardar la imagen: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Detección de Objetos")),
      body: Stack(
        children: [
          CameraPreview(_controller),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _detectionResult,
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _modelStatus,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
