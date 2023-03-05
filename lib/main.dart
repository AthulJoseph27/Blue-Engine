import 'dart:convert';

import 'package:flutter/material.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;
  var text = "You have pushed the button this many times:";
  final colors = [Colors.redAccent, Colors.blue, Colors.green, Colors.amber];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    invokePlatformMethod(PlatformFunctions.sendMessage, {'counter' : _counter});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: eventStreamController.stream,
      builder: (context, snapshot) {
        if(snapshot.hasData) {
          text = jsonDecode(snapshot.data)['page'];
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  text,
                ),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
            // backgroundColor: ,
          ),
        );
      },
    );
  }
}
