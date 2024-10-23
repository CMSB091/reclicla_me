import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

Widget buildLottieAnimation({
  required String path,
  double width = 100.0,
  double height = 100.0,
  BoxFit fit = BoxFit.contain,
}) {
  return Lottie.asset(
    path,
    width: width,
    height: height,
    fit: fit,
  );
}
