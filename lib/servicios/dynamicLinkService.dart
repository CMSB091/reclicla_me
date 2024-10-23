import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:recila_me/widgets/datosPersonales.dart';

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

/* Este código pertenece a un servicio en Flutter llamado DynamicLinkService, cuya función es gestionar los enlaces dinámicos utilizando la biblioteca de Firebase Dynamic Links.

Descripción de la funcionalidad:
initDynamicLinks(BuildContext context):

Esta función inicializa la escucha de enlaces dinámicos en la aplicación.
Utiliza FirebaseDynamicLinks.instance.getInitialLink() para obtener el enlace dinámico inicial, cuando la aplicación se abre desde un enlace profundo.
Luego escucha los enlaces dinámicos a través de FirebaseDynamicLinks.instance.onLink.listen(...) para manejar enlaces que lleguen mientras la aplicación ya está abierta.
Los enlaces son manejados por la función _handleDeepLink.
_handleDeepLink(PendingDynamicLinkData? dynamicLinkData, BuildContext context):

Esta función se encarga de manejar el enlace profundo cuando la app recibe un enlace dinámico.
Si hay un enlace presente, se navega a la pantalla de DatosPersonales, pasando como parámetro el correo que se extrae de los parámetros de la URL.*/
