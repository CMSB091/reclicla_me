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
      // Aquí puedes manejar el enlace profundo según tu necesidad.
      // Por ejemplo, redirigir al usuario a la página de datos personales.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DatosPersonales(
            correo: deepLink.queryParameters['email'] ?? '', // Pasar el correo electrónico extraído del deep link
            desdeInicio: false,
            cameras: [],
          ),
        ),
      );
    }
  }
}
