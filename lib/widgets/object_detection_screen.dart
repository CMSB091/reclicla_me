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

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  void _resetScreen() {
    debugPrint('Reseteando la pantalla...');
    setState(() {
      filePath = null;
      label = '';
      confidence = 0.0;
      objectDetected = false;
      _loading = true;
    });
  }

  Future<void> _guardarItemSeleccionado(
      BuildContext context, String detectedItem) async {
    final TextEditingController itemNameController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Guardar "$detectedItem"',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: itemNameController,
                        maxLength: 20,
                        decoration: InputDecoration(
                          labelText: 'Nombre del artículo',
                          hintText: 'Ingresa un nombre',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      if (isSaving)
                        const Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: CircularProgressIndicator(),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final itemName =
                                        itemNameController.text.trim();
                                    if (itemName.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'El nombre del artículo no puede estar vacío.'),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isSaving = true;
                                    });

                                    await FirestoreService.saveScannedItem(
                                      context: context,
                                      detectedItem: detectedItem,
                                      userEmail: widget.userEmail,
                                      itemName: itemName,
                                    );

                                    setState(() {
                                      isSaving = false;
                                    });

                                    Navigator.of(context).pop();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Artículo guardado exitosamente.'),
                                      ),
                                    );

                                    // Limpia las variables y reinicia la pantalla
                                    _resetScreen();
                                  },
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Center(
                    child: _loading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Image.asset(
                                'assets/images/recycle-icons8.png',
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: 50),
                            ],
                          )
                        : filePath != null
                            ? Container(
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
                                  child:
                                      Image.file(filePath!, fit: BoxFit.cover),
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  if (label.isNotEmpty)
                    Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "Precisión: ${confidence.toStringAsFixed(0)}%",
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
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
                          icon: const FaIcon(FontAwesomeIcons.images),
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
                          icon: const FaIcon(FontAwesomeIcons.camera),
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
                            icon: const FaIcon(FontAwesomeIcons.recycle),
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
                            icon: const FaIcon(FontAwesomeIcons.save),
                            label: const Text('Guardar Item'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
