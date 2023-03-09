import 'dart:ui';

import 'package:flutter/cupertino.dart';

enum RenderEngine {
  aurora,
  comet,
}

enum RenderQuality {
  high,
  medium,
  low
}

enum SwiftMethods {
  renderImage,
  renderAnimation,
  updateViewportSettings,
  updateSceneSettings,
  updateCameraSettings, importScene
}

class Int2 {
  int  x = 0, y = 0;
  Int2({required this.x, required this.y});

  Map<String, dynamic> toJson() => {
    'x' : x,
    'y' : y,
  };
}

const transparent = Color(0x00000000);

class LightTheme {
  static const activeBlue = Color.fromARGB(255, 0, 122, 255);
}