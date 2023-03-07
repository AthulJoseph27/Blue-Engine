import 'dart:convert';

import 'package:blue_engine/Screens/SplashScreen.dart';
import 'package:blue_engine/globals.dart';
import 'package:blue_engine/screens/RenderAnimation.dart';
import 'package:blue_engine/screens/RenderImage/RenderImageView.dart';
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
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      // theme: CupertinoThemeData(
      //   brightness: Brightness.dark,
      // ),
      theme: ThemeData(brightness: Brightness.light, primaryColor: LightTheme.activeBlue),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var page = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: eventStreamController.stream,
      builder: (context, snapshot) {
        if(snapshot.hasData) {
          page = jsonDecode(snapshot.data)['page'];
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
