import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:recila_me/widgets/datos_personales.dart';

class DynamicLinkService {
  Future<void> initDynamicLinks(BuildContext context) async {
    final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
    _handleDeepLink(data, context);

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      _handleDeepLink(dynamicLinkData, context);
    }).onError((error) {
      print('Error handling dynamic link: $error');
    });
  }

  void _handleDeepLink(PendingDynamicLinkData? dynamicLinkData, BuildContext context) {
    final Uri? deepLink = dynamicLinkData?.link;

    if (deepLink != null) {
      // Manejo del enlace profundo, para cuando el usuario valida su email
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DatosPersonales(
            correo: deepLink.queryParameters['email'] ?? '',
            desdeInicio: false,
            cameras: const [],
          ),
        ),
      );
    }
  }
}
