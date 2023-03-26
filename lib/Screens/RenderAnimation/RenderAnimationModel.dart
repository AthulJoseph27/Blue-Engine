import 'package:blue_engine/globals.dart';

class RenderAnimationModel {
  static var renderEngine = RenderEngine.aurora;
  static var quality = RenderQuality.medium;
  static var resolution = Int2(x: 1080, y: 720);
  static var maxBounce = 6;
  static var record = false;
  static var saveLocation = '/Users/athuljoseph/Downloads/Animation/';

  static Future<bool> load() async {
    throw UnimplementedError();
  }

  static Future<bool> save() async {
    throw UnimplementedError();
  }

  static Map<String, dynamic> toJson()=> {
    'renderEngine' : renderEngine.name,
    'quality' :  quality.name,
    'resolution' : resolution.toJson(),
    'maxBounce' : maxBounce,
    'saveLocation' : saveLocation,
  };

}