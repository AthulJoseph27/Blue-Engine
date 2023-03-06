import 'package:flutter/cupertino.dart';

class RenderAnimationPage extends StatefulWidget {
  const RenderAnimationPage({Key? key}) : super(key: key);

  @override
  State<RenderAnimationPage> createState() => _RenderAnimationPageState();
}

class _RenderAnimationPageState extends State<RenderAnimationPage> {
  @override
  Widget build(BuildContext context) {
    return Container(color: CupertinoColors.activeGreen,);
  }
}
