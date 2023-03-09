import 'package:blue_engine/Screens/Settings/Tabs/Scene/SceneSettingsController.dart';
import 'package:blue_engine/Widgets/CustomDropDownMenu.dart';
import 'package:blue_engine/Widgets/SettingsRow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'SceneSettingsModel.dart';

class SceneSettingsView extends StatefulWidget {
  const SceneSettingsView({Key? key}) : super(key: key);

  @override
  State<SceneSettingsView> createState() => _SceneSettingsViewState();
}

class _SceneSettingsViewState extends State<SceneSettingsView> {
  final spacingRatio = 0.7;
  final controller = SceneSettingsController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CupertinoColors.systemGrey5)
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        padding: const EdgeInsets.only(top: 30),
        height: size.height - 180,
        width: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsRow(
              spacingRatio: spacingRatio,
              firstChild: Text(
                'Scene :',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              secondChild: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: CustomDropDownMenu(
                      list: SceneSettingsModel.scenes,
                      onChanged: controller.onSceneChanged,
                    ),
                  ),
                  const SizedBox(width: 20,),
                  IconButton(onPressed: (){}, icon: Icon(CupertinoIcons.upload_circle, color: Theme.of(context).primaryColor), tooltip: "Import new scene",),
                ],
              )
            ),
            SettingsRow(
              spacingRatio: spacingRatio,
              firstChild: Text(
                'Skybox :',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              secondChild: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: CustomDropDownMenu(
                      list: SceneSettingsModel.skyBoxes,
                      onChanged: controller.onSkyboxChanged,
                    ),
                  ),
                  const SizedBox(width: 20,),
                  IconButton(onPressed: (){}, icon: Icon(CupertinoIcons.upload_circle, color: Theme.of(context).primaryColor), tooltip: "Import new skybox",),
                ],
              ),
            ),
            SettingsRow(
              firstChild: Text(
                'Ambient Lighting :',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: StreamBuilder<double>(
                    stream: controller.ambientLightController.stream,
                    initialData: SceneSettingsModel.ambientBrightness,
                    builder: (context, snapshot) {
                      var value = snapshot.data ?? 0.0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, right: 12),
                            child: SizedBox(
                                width: 240,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 240,
                                      child: CupertinoSlider(
                                        value: value,
                                        onChanged: controller.onAmbientLightChanged,
                                        min: 0.0,
                                        max: 1.0,
                                        divisions: 20,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text('0.0', style: Theme.of(context).textTheme.caption,),
                                        const Spacer(),
                                        Text('1.0', style: Theme.of(context).textTheme.caption,),
                                      ],
                                    ),
                                  ],
                                )),
                          ),
                          SizedBox(
                            width: 48,
                            height: 32,
                            child: CupertinoTextField(
                              controller: controller.ambientLightTextController,
                              focusNode: controller.ambientLightFocusNode,
                              onChanged: controller.onAmbientLightTextChanged,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp("[0-9.]"))],
                            ),
                          ),
                        ],
                      );
                    }
                ),
              ),
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
                    onPressed: controller.import3DModel,
                    child: const Center(child: Text('Import', style: TextStyle(fontSize: 16),)),),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
