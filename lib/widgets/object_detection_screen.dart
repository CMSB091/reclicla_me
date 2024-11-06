import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'mySplashScreen.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

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

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección de Objetos'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 30),
            Center(
              child: _loading
                  ? SizedBox(
                      width: 280,
                      child: Column(
                        children: <Widget>[
                          Image.asset('assets/images/recycle-icons8.png',
                              color: Theme.of(context).primaryColor),
                          const SizedBox(height: 50)
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
            const Spacer(),
            if (objectDetected)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MySplash(
                        detectedObject: label, // Pasa el objeto detectado
                      ),
                    ),
                  );
                },
                child: const Text('Consultar sobre reciclaje'),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickImageGallery,
                    child: const Text('Seleccionar desde Galería'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickImageCamera,
                    child: const Text('Usar Cámara'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
