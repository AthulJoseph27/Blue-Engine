import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum RenderEngine {
  aurora,
  comet,
}

enum RenderQuality {
  high,
  medium,
  low
}

const supportedModelExtension = ['obj', 'usdc'];

class Int2 {
  int  x = 0, y = 0;
  Int2({required this.x, required this.y});

  Map<String, dynamic> toJson() => {
    'x' : x,
    'y' : y,
  };
}

class Double3 {
  final double x, y, z;
  const Double3({required this.x, required this.y, required this.z});

  Map<String, dynamic> toJson() => {
    'x' : x,
    'y' : y,
    'z' : z,
  };
}

final GlobalKey<ScaffoldMessengerState> settingsScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

SnackBar showSnackBar(String message, {bool error = false}) {
  return SnackBar(
    backgroundColor: error ? CupertinoColors.systemRed : const Color(0xff04cfb5),
    content: Text(
      message,
      style: const TextStyle(
        color: CupertinoColors.white,
        fontSize: 16,
      ),
    ),);
}