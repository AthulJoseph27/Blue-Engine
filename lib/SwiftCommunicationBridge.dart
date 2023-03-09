import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String methodChannelName = "flutter_method_channel";
const String eventChannelName = "flutter_event_channel";

enum SwiftMethods {
  renderImage,
  renderAnimation,
  updateViewportSettings,
  updateSceneSettings,
  updateCameraSettings,
  importScene,
}

const methodChannel = MethodChannel(methodChannelName);
const eventChannel = EventChannel(eventChannelName);
final eventStreamController = StreamController<dynamic>();

Future<void> invokePlatformMethod(SwiftMethods function, Map<String, dynamic> arguments) async {
  try {
    await methodChannel.invokeMethod(function.name, jsonEncode(arguments));
  } on PlatformException catch (e) {
    if (kDebugMode) {
      print("Failed to send message: '${e.message}'.");
    }
  }
}

void initializeEventChannel() {
  eventChannel.receiveBroadcastStream().listen(eventStreamController.sink.add);
}