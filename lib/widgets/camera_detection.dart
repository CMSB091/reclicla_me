import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recila_me/widgets/noticias.dart';

class CameraDetection extends StatefulWidget {
  const CameraDetection({super.key});

  @override
  State<CameraDetection> createState() => _CameraDetectionState();
}

class _CameraDetectionState extends State<CameraDetection> {
  File? filePath;
  String label = '';
  double confidence = 0.0;
  bool _loading = true;

  Future<void> _tfliteInit() async {
    await Tflite.loadModel(
      model: "assets/converted_tflite/model_unquant.tflite",
      labels: "assets/converted_tflite/labels.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
  }

  pickImageCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    var imageMap = File(image.path);
    setState(() {
      filePath = imageMap;
    });

    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
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
      });
      return;
    }

    setState(() {
      confidence = (recognitions[0]['confidence'] * 100);
      label = recognitions[0]['label'].toString();
      _loading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();
    _tfliteInit();
    pickImageCamera(); // Iniciar con la cámara
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección de Objetos'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 30),
            Center(
              child: _loading
                  ? const CircularProgressIndicator()
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
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              "Precisión: ${confidence.toStringAsFixed(0)}%",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            if (!_loading)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (label.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NoticiasChatGPT(initialPrompt: 'initialPrompt: "Quiero que me recomiendes cómo reciclar este producto escaneado: $label}',
                                detectedObject: label,),
                          ),
                        );
                      } else {
                        debugPrint("Error: No se detectó ningún objeto.");
                      }
                    },
                    child: const Text('Consultar sobre reciclaje'),
                  ),
                  ElevatedButton(
                    onPressed: pickImageCamera,
                    child: const Text('Tomar Otra'),
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
