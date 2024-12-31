import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:recila_me/clases/firestore_service.dart';
import 'package:recila_me/clases/funciones.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/widgets/mySplashScreen.dart';
import 'package:recila_me/widgets/noticias.dart';

class ObjectDetectionScreen extends StatefulWidget {
  final String userEmail; // Email del usuario
  const ObjectDetectionScreen({super.key, required this.userEmail});

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  File? filePath;
  String label = '';
  double confidence = 0.0;
  bool _loading = true;
  bool objectDetected = false;

  @override
  void initState() {
    super.initState();
    _tfliteInit();
  }

  Future<void> _tfliteInit() async {
    await Tflite.loadModel(
      model: "assets/converted_tflite/model_unquant.tflite",
      labels: "assets/converted_tflite/labels.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
  }

  pickImageGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      filePath = File(image.path);
    });
    _runModel(image.path);
  }

  pickImageCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      filePath = File(image.path);
    });
    _runModel(image.path);
  }

  _runModel(String imagePath) async {
    var recognitions = await Tflite.runModelOnImage(
      path: imagePath,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 2,
      threshold: 0.7,
      asynch: true,
    );

    if (recognitions == null || recognitions.isEmpty) {
      setState(() {
        label = "No se detectaron objetos.";
        confidence = 0.0;
        _loading = false;
        objectDetected = false;
      });
      return;
    }

    setState(() {
      confidence = (recognitions[0]['confidence'] * 100);
      label = recognitions[0]['label'].toString();
      _loading = false;
      objectDetected = true;
    });
  }

  void _mostrarAyuda(BuildContext context) {
    Funciones.mostrarModalDeAyuda(
      context: context,
      titulo: 'Ayuda',
      mensaje:
          'Utiliza la cámara del celular para escanear objetos reciclables.\n'
          'También puedes seleccionar imagenes de objetos desde la galería\n'
          'Puedes obtener recomendaciones del objeto escaneado, como así también\n'
          'guardarlos en la base de datos para luego obtener un resumen tu huella\n'
          'de carbono.',
    );
  }

  Future<void> _guardarItemSeleccionado(
      BuildContext context, String detectedItem) async {
    await FirestoreService.saveScannedItem(
      context: context,
      detectedItem: detectedItem,
      userEmail: widget.userEmail, // Usa el email pasado al widget
    );

    setState(() {
      filePath = null;
      label = '';
      confidence = 0.0;
      objectDetected = false;
      _loading = true;
    });
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detección de Objetos',
          style: TextStyle(
            fontFamily: 'Artwork',
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.green.shade200,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.house, color: Colors.black),
          onPressed: () {
            Funciones.navigateToHome(context);
          },
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.infoCircle),
            onPressed: () {
              _mostrarAyuda(context);
            },
          ),
        ],
      ),
      body: BlurredBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Spacer(), // Agrega un espacio flexible para empujar hacia abajo
              Center(
                child: _loading
                    ? SizedBox(
                        width: 280,
                        child: Column(
                          children: <Widget>[
                            Image.asset(
                              'assets/images/recycle-icons8.png',
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      )
                    : Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(filePath!, fit: BoxFit.cover),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Precisión: ${confidence.toStringAsFixed(0)}%",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(), // Este Spacer empuja hacia abajo los botones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: pickImageGallery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      icon: const FaIcon(
                          FontAwesomeIcons.images), // Ícono para galería
                      label: const Text('Seleccionar desde Galería'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: pickImageCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      icon: const FaIcon(
                          FontAwesomeIcons.camera), // Ícono para cámara
                      label: const Text('Usar Cámara'),
                    ),
                  ),
                ],
              ),

              if (objectDetected) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MySplash(
                                nextScreen: NoticiasChatGPT(
                                  initialPrompt:
                                      "Quiero que me recomiendes cómo reciclar este producto escaneado: $label",
                                  detectedObject: label,
                                ),
                                lottieAnimation:
                                    'assets/animations/lottie-robot.json',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        icon: const FaIcon(FontAwesomeIcons
                            .recycle), // Ícono para consultar reciclaje
                        label: const Text('Consultar sobre reciclaje'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _guardarItemSeleccionado(context, label);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        icon: const FaIcon(
                            FontAwesomeIcons.save), // Ícono para guardar
                        label: const Text('Guardar Item'),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
