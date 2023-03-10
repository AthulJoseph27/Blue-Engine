import 'package:blue_engine/Screens/SplashScreen.dart';
import 'package:blue_engine/screens/RenderAnimation.dart';
import 'package:blue_engine/screens/RenderImage/RenderImageView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Screens/Loading.dart';
import 'Screens/Settings/SettingsView.dart';
import 'SwiftCommunicationBridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeEventChannel();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, primaryColor: CupertinoColors.activeBlue),
      home: const FlutterUI(),
    );
  }
}

class FlutterUI extends StatefulWidget {
  const FlutterUI({Key? key}) : super(key: key);

  @override
  State<FlutterUI> createState() => _FlutterUIState();
}

class _FlutterUIState extends State<FlutterUI> {
  var page = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: pageController.stream,
      builder: (context, snapshot) {
        if(snapshot.hasData) {
          page = snapshot.data['page'];
        }
        return SafeArea(child: getPage(page));
      },
    );
  }

  Widget getPage(String page) {
    switch(page) {
      case 'Settings':
        return const SettingsPage();
      case 'RenderImage':
        return const RenderImagePage();
      case 'RenderAnimation':
        return const RenderAnimationPage();
      case 'Loading':
        return const Loading();
      default:
        return const SplashScreen();
    }
  }
}
