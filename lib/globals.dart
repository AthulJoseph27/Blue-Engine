enum RenderEngine {
  aurora,
  velocity,
}

enum RenderQuality {
  high,
  medium,
  low
}

enum SwiftMethods {
  renderImage,
  renderAnimation,
  updateViewPortSettings,
  updateSceneSettings,
  updateCameraSettings
}

class Int2 {
  int  x = 0, y = 0;
  Int2({required this.x, required this.y});

  Map<String, dynamic> toJson() => {
    'x' : x,
    'y' : y,
  };
}
