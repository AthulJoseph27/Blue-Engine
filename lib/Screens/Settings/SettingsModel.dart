import 'package:blue_engine/Screens/Settings/Tabs/Scene/SceneSettingsModel.dart';
import 'package:blue_engine/Screens/Settings/Tabs/ViewPort/ViewPortModel.dart';

class SettingsModel {
  static var viewPortSettings = ViewPortModel();
  static var sceneSettings = SceneSettingsModel();

  Future<bool> load() async {
    throw UnimplementedError();
  }

  Future<bool> save() async {
    throw UnimplementedError();
  }
}