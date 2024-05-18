import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class myInicio extends StatelessWidget{
  const myInicio({super.key});

  @override
  Widget build(Object context) {
    return  Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light
        ),
        backgroundColor: Colors.green.shade200,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children:[ 
          Text("INICIO",style: TextStyle(color: Colors.black),
          ),
          ],
          ),
      ),
    );
  }
  
}