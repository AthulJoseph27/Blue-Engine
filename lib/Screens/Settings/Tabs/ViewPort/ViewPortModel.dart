import 'package:blue_engine/globals.dart';

class ViewPortModel {
  static var cometViewPortModel = AuroraViewPortModel();
  static var velocityViewPortModel = VelocityViewPortModel();
}

class AuroraViewPortModel {
  var maxBounce = 6;
  var resolution = RenderQuality.high;
  var tileSize = Int2(x: 8, y: 8);
  var controlSensitivity = ControlSensitivity();
}

class VelocityViewPortModel {
  var controlSensitivity = ControlSensitivity();
}

class ControlSensitivity {
  var keyboardSensitivity = KeyboardSensitivity();
  var trackpadSensitivity = TrackpadSensitivity();
}

class KeyboardSensitivity {
  var translation = 1.0;
  var rotation = 1.0;
}

class TrackpadSensitivity {
  var zoom = 1.0;
  var rotation = 1.0;
}