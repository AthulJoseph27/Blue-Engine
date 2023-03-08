const List<String> scenes = ['Cornell', 'Sponza', 'Fireplace Room', 'San Miguel'];
const List<String> skyBoxes = ['Sky', 'Jungle', 'NightCity', 'Beach'];

class SceneSettingsModel {
  static var scene = scenes[0];
  static var skybox = skyBoxes[0];
  static var ambientBrightness = 0.1;

  static Map<String, dynamic> toJson() => {
    'scene' : scene,
    'skybox' : skybox,
    'ambient' : ambientBrightness,
  };

}