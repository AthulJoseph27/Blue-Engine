import 'dart:async';
import 'dart:math';

import 'package:blue_engine/SwiftCommunicationBridge.dart';
import 'package:flutter/cupertino.dart';

import 'RenderAnimationModel.dart';

class RenderAnimationController {
  final maxBounceController = TextEditingController(text: RenderAnimationModel.maxBounce.toString());
  final resolutionXController = TextEditingController(text: RenderAnimationModel.resolution.x.toString());
  final resolutionYController = TextEditingController(text: RenderAnimationModel.resolution.y.toString());
  final saveLocationController = TextEditingController(text: RenderAnimationModel.saveLocation);

  final maxBounceStreamController = StreamController<int>();
  final maxBounceFocusNode = FocusNode();

  final recordModeStreamController = StreamController<bool>();

  RenderAnimationController() {
    resolutionXController.addListener(() {
      RenderAnimationModel.resolution.x = int.tryParse(resolutionXController.text) ?? RenderAnimationModel.resolution.x;
    });
    resolutionYController.addListener(() {
      RenderAnimationModel.resolution.y = int.tryParse(resolutionYController.text) ?? RenderAnimationModel.resolution.y;
    });
    saveLocationController.addListener(() {
      RenderAnimationModel.saveLocation = saveLocationController.text;
    });
  }

  void setMaxBounce(String? value) {
    if(value == null) {
      return;
    }

    int maxBounce = int.tryParse(value) ?? 6;
    maxBounce = max(maxBounce, 1);
    RenderAnimationModel.maxBounce = maxBounce;
  }
  
  void switchCamera(bool value) {
    RenderAnimationModel.record = value;
    recordModeStreamController.sink.add(value);
    invokePlatformMethod(SwiftMethods.switchCamera, {'recordMode' : RenderAnimationModel.record});
  }

  void renderAnimation() {
    invokePlatformMethod(SwiftMethods.renderAnimation, RenderAnimationModel.toJson());
  }
}