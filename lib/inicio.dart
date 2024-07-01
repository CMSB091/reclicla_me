import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyInicio extends StatelessWidget {
  const MyInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.green.shade200,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        title: const Text('Bienvenido !!'),
        leading: IconButton(
          icon: Image.asset('assets/images/exitDoor.png'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        
      ),
    );
  }
}
