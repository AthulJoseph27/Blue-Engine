import 'package:blue_engine/Screens/RenderImage/RenderImageController.dart';
import 'package:blue_engine/Screens/RenderImage/RenderImageModel.dart';
import 'package:blue_engine/Screens/Settings/SettingsModel.dart';
import 'package:blue_engine/Widgets/CupertinoRow.dart';
import 'package:blue_engine/globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class RenderImagePage extends StatefulWidget {
  const RenderImagePage({Key? key}) : super(key: key);

  @override
  State<RenderImagePage> createState() => _RenderImagePageState();
}

class _RenderImagePageState extends State<RenderImagePage> {
  final spacingRatio = 0.8;
  final controller = RenderImageController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoRow(
              firstChild: Text(
                'Render Engine :',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
              secondChild: CupertinoSegmentedControl<RenderEngine>(
                selectedColor: CupertinoColors.activeBlue,
                groupValue: RenderImageModel.renderEngine,
                onValueChanged: (RenderEngine value) {
                  setState(() {
                    RenderImageModel.renderEngine = value;
                  });
                },
                children: const <RenderEngine, Widget>{
                  RenderEngine.aurora: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Aurora',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  RenderEngine.velocity: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Velocity',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                },
              ),
              spacingRatio: spacingRatio,
            ),
            CupertinoRow(
              firstChild: Text(
                'Quality :',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
              secondChild: CupertinoSegmentedControl<RenderQuality>(
                selectedColor: CupertinoColors.activeBlue,
                groupValue: RenderImageModel.quality,
                onValueChanged: (RenderQuality value) {
                  setState(() {
                    RenderImageModel.quality = value;
                  });
                },
                children: const <RenderQuality, Widget>{
                  RenderQuality.high: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'High',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  RenderQuality.medium: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Medium',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  RenderQuality.low: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Low',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                },
              ),
              spacingRatio: spacingRatio,
            ),
            CupertinoRow(
              firstChild: Text(
                'Resolution :',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
              secondChild: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: SizedBox(
                      width: 80,
                      child: CupertinoTextField(
                        controller: controller.resolutionXController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('x'),
                  ),
                  SizedBox(
                    width: 80,
                    child: CupertinoTextField(
                      controller: controller.resolutionYController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              spacingRatio: spacingRatio,
            ),
            CupertinoRow(
              firstChild: Text(
                'Save Location :',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SizedBox(
                  width: 400,
                  child: CupertinoTextField(
                    controller: controller.saveLocationController,
                  ),
                ),
              ),
              spacingRatio: spacingRatio,
            ),
            CupertinoRow(
              firstChild: Text(
                'Persistent render window:',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
              secondChild: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    height: 32,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: CupertinoSwitch(
                          activeColor: CupertinoTheme.of(context).primaryColor,
                          value: RenderImageModel.keepAlive,
                          onChanged: (value) {
                            setState(() {
                              RenderImageModel.keepAlive = value;
                            });
                          }),
                    ),
                  ),),
              spacingRatio: spacingRatio,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: SizedBox(
                  height: 32,
                  width: 100,
                  child: CupertinoButton(
                    color: CupertinoTheme.of(context).primaryColor,
                    padding: const EdgeInsets.all(2.0),
                    onPressed: controller.renderImage,
                    child: const Center(child: Text('Render', style: TextStyle(fontSize: 16),)),),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
