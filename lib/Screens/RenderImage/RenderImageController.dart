import 'package:blue_engine/Screens/RenderImage/RenderImageModel.dart';
import 'package:blue_engine/SwiftCommunicationBridge.dart';
import 'package:flutter/cupertino.dart';

class RenderImageController {
  final resolutionXController = TextEditingController(text: RenderImageModel.resolution.x.toString());
  final resolutionYController = TextEditingController(text: RenderImageModel.resolution.y.toString());
  final saveLocationController = TextEditingController(text: RenderImageModel.saveLocation);

  RenderImageController() {
    resolutionXController.addListener(() {
      RenderImageModel.resolution.x = int.tryParse(resolutionXController.text) ?? RenderImageModel.resolution.x;
    });
    resolutionYController.addListener(() {
      RenderImageModel.resolution.y = int.tryParse(resolutionYController.text) ?? RenderImageModel.resolution.y;
    });
    saveLocationController.addListener(() {
      RenderImageModel.saveLocation = saveLocationController.text;
    });
  }

  void renderImage() {
    invokePlatformMethod(SwiftMethods.renderImage, RenderImageModel.toJson());
  }
}