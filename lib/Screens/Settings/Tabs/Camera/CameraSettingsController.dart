import 'dart:async';
import 'dart:convert';

import 'package:blue_engine/Screens/Settings/Tabs/Camera/CameraSettingsModel.dart';
import 'package:blue_engine/SwiftCommunicationBridge.dart';
import 'package:blue_engine/globals.dart';
import 'package:flutter/cupertino.dart';

class CameraSettingsController {
  final positionController = StreamController<Double3>();
  final rotationController = StreamController<Double3>();
  final pX = TextEditingController();
  final pY = TextEditingController();
  final pZ = TextEditingController();
  final rX = TextEditingController();
  final rY = TextEditingController();
  final rZ = TextEditingController();
  final pXFocus = FocusNode();
  final pYFocus = FocusNode();
  final pZFocus = FocusNode();
  final rXFocus = FocusNode();
  final rYFocus = FocusNode();
  final rZFocus = FocusNode();

  void onPositionChanged(Double3 value) {
    CameraSettingsModel.position = value;
    invokePlatformMethod(SwiftMethods.updateCameraSettings, CameraSettingsModel.toJson());
  }

  void onPositionXChanged(String value) {
    var x = double.tryParse(value) ?? CameraSettingsModel.position.x;
    CameraSettingsModel.position = Double3(x: x, y: CameraSettingsModel.position.y, z: CameraSettingsModel.position.z);
    invokePlatformMethod(SwiftMethods.updateCameraSettings, CameraSettingsModel.toJson());
  }

  void onPositionYChanged(String value) {
    var y = double.tryParse(value) ?? CameraSettingsModel.position.y;
    CameraSettingsModel.position = Double3(x: CameraSettingsModel.position.x, y: y, z: CameraSettingsModel.position.z);
    invokePlatformMethod(SwiftMethods.updateCameraSettings, CameraSettingsModel.toJson());
  }

  void onPositionZChanged(String value) {
    var z = double.tryParse(value) ?? CameraSettingsModel.position.z;
    CameraSettingsModel.position = Double3(x: CameraSettingsModel.position.x, y: CameraSettingsModel.position.y, z: z);
    invokePlatformMethod(SwiftMethods.updateCameraSettings, CameraSettingsModel.toJson());
  }

  void onRotationXChanged(String value) {
    var x = double.tryParse(value) ?? CameraSettingsModel.rotation.x;
    CameraSettingsModel.rotation = Double3(x: x, y: CameraSettingsModel.rotation.y, z: CameraSettingsModel.rotation.z);
    invokePlatformMethod(SwiftMethods.updateCameraSettings, CameraSettingsModel.toJson());
  }

  void onRotationYChanged(String value) {
    var y = double.tryParse(value) ?? CameraSettingsModel.rotation.y;
    CameraSettingsModel.rotation = Double3(x: CameraSettingsModel.rotation.x, y: y, z: CameraSettingsModel.rotation.z);
    invokePlatformMethod(SwiftMethods.updateCameraSettings, CameraSettingsModel.toJson());
  }

  void onRotationZChanged(String value) {
    var z = double.tryParse(value) ?? CameraSettingsModel.rotation.z;
    CameraSettingsModel.rotation = Double3(x: CameraSettingsModel.rotation.x, y: CameraSettingsModel.rotation.y, z: z);
    invokePlatformMethod(SwiftMethods.updateCameraSettings, CameraSettingsModel.toJson());
  }

  void onRotationChanged(Double3 value) {
    CameraSettingsModel.rotation = value;
    invokePlatformMethod(SwiftMethods.updateCameraSettings, CameraSettingsModel.toJson());
  }

  Future<void> updateCameraSettings() async {
    var json = jsonDecode(await invokePlatformMethod(SwiftMethods.getCameraSettings, {}));
    CameraSettingsModel.fromJson(json);
    pX.text = CameraSettingsModel.position.x.toString();
    pY.text = CameraSettingsModel.position.y.toString();
    pZ.text = CameraSettingsModel.position.z.toString();
    rX.text = CameraSettingsModel.rotation.x.toString();
    rY.text = CameraSettingsModel.rotation.y.toString();
    rZ.text = CameraSettingsModel.rotation.z.toString();
    positionController.sink.add(CameraSettingsModel.position);
    rotationController.sink.add(CameraSettingsModel.rotation);
  }
}