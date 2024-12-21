import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

class Utilidades {
  // Para verificar si una app esta instalada en el dispositivo, en este caso whatsapp
  void checkIfAppIsInstalled() async {
    bool isInstalled = await DeviceApps.isAppInstalled('com.whatsapp');
    if (isInstalled) {
      debugPrint('WhatsApp está instalado');
    } else {
      debugPrint('WhatsApp no está instalado');
    }
  }
  // Recupera un listado de aplicaciones instaladas en el dispositivo
  void listInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications();
    for (var app in apps) {
      debugPrint('Nombre del paquete: ${app.packageName}');
    }
  }
}
