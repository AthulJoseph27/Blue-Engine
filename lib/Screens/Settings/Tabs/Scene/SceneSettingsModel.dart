class SceneSettingsModel {
  static const List<String> _scenes = ['Cornell', 'Sponza', 'Fireplace Room', 'San Miguel', 'Custom'];
  static const List<String> _skyBoxes = ['Sky', 'Jungle', 'NightCity', 'Beach', 'Custom'];
  static var hasImportedScene = false;
  static var hasImportedSkybox = false;
  static var scene = scenes[0];
  static var skybox = skyBoxes[0];
  static var ambientBrightness = 0.1;

  static List<String> get scenes {
    List<String> scenes = List.from(_scenes);
    if(!hasImportedScene) {
      scenes.removeLast();
    }
    return scenes;
  }

  static List<String> get skyBoxes {
    List<String> skyBoxes = List.from(_skyBoxes);
    if(!hasImportedSkybox) {
      skyBoxes.removeLast();
    }
    return skyBoxes;
  }

  static Map<String, dynamic> toJson() => {
    'scene' : scene,
    'skybox' : skybox,
    'ambient' : ambientBrightness,
  };
}