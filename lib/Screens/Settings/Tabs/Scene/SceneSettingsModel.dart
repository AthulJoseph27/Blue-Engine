enum Scene {
  cornell,
  sponza,
  fireplaceRoom,
  sanMiguel
}

enum SkyBox {
  sky,
  jungle,
  city,
  beach
}

class SceneSettingsModel {
  var currentScene = Scene.cornell;
  var skybox = SkyBox.sky;
  var ambientBrightness = 1.0;
}