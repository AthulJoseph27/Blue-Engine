import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

const String methodChannelName = "flutter_method_channel";
const String eventChannelName = "flutter_event_channel";

const methodChannel = MethodChannel(methodChannelName);
const eventChannel = EventChannel(eventChannelName);
final eventStreamController = StreamController<dynamic>();

class PlatformFunctions {
  static const String sendMessage = 'send_message';
}

Future<void> invokePlatformMethod(String function, Map<String, dynamic> arguments) async {
  try {
    await methodChannel.invokeMethod(function, jsonEncode(arguments));
  } on PlatformException catch (e) {
    print("Failed to send message: '${e.message}'.");
  }
}

void initializeEventChannel() {
  eventChannel.receiveBroadcastStream().listen(eventStreamController.sink.add);
}