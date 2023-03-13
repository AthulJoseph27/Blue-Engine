import 'package:blue_engine/Screens/RenderImage/RenderImageController.dart';
import 'package:blue_engine/Screens/RenderImage/RenderImageModel.dart';
import 'package:blue_engine/Widgets/SettingsRow.dart';
import 'package:blue_engine/Widgets/MaterialSegmentedControl.dart';
import 'package:blue_engine/globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsRow(
              firstChild: Text(
                'Render Engine :',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              secondChild: MaterialSegmentedControl<RenderEngine>(
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
                  RenderEngine.comet: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Comet',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                },
              ),
              spacingRatio: spacingRatio,
            ),
            SettingsRow(
              firstChild: Text(
                'Quality :',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              secondChild: MaterialSegmentedControl<RenderQuality>(
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
            SettingsRow(
              firstChild: Text(
                'Resolution :',
                style: Theme.of(context).textTheme.titleMedium,
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
            SettingsRow(
              firstChild: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Max Bounce :',
                  style: (RenderImageModel.renderEngine == RenderEngine.aurora) ? Theme.of(context).textTheme.titleMedium
                  :
                  const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey3,
                  ) ,
                ),
              ),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: SizedBox(
                  width: 80,
                  child: StreamBuilder<int>(
                      stream: controller.maxBounceStreamController.stream,
                      builder: (context, snapshot) {
                        return CupertinoTextField(
                          enabled: RenderImageModel.renderEngine == RenderEngine.aurora,
                          controller: controller.maxBounceController,
                          focusNode: controller.maxBounceFocusNode,
                          onChanged: controller.setMaxBounce,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        );
                      }
                  ),
                ),
              ),
              spacingRatio: spacingRatio,
            ),
            SettingsRow(
              firstChild: Text(
                'Save Location :',
                style: Theme.of(context).textTheme.titleMedium,
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
            SettingsRow(
              firstChild: Text(
                'Persistent render window:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              secondChild: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    height: 32,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: CupertinoSwitch(
                          activeColor: Theme.of(context).primaryColor,
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
                    color: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    // style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).primaryColor),),
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
