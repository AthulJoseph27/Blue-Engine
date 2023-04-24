import 'package:blue_engine/Screens/Settings/Tabs/Camera/CameraSettingsController.dart';
import 'package:blue_engine/Widgets/SettingsRow.dart';
import 'package:blue_engine/Widgets/XYZInputBoxWidget.dart';
import 'package:blue_engine/globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CameraSettingsView extends StatefulWidget {
  const CameraSettingsView({Key? key}) : super(key: key);

  @override
  State<CameraSettingsView> createState() => _CameraSettingsViewState();
}

class _CameraSettingsViewState extends State<CameraSettingsView> {
  final controller = CameraSettingsController();
  final spacingRatio = 0.56;

  @override
  void initState() {
    controller.updateCameraSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        padding: const EdgeInsets.only(top: 30),
        height: size.height - 180,
        width: 800,
        child: Column(
          children: [
            const SizedBox(
              height: 24,
            ),
            SettingsRow(
              spacingRatio: spacingRatio,
              firstChild: Text(
                'Position : ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              secondChild: const SizedBox(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 112),
              child: StreamBuilder<Double3>(
                  stream: controller.positionController.stream,
                  builder: (context, snapshot) {
                    return getXYZInputBox(
                        context,
                        controller.pX,
                        controller.pY,
                        controller.pZ,
                        controller.pXFocus,
                        controller.pYFocus,
                        controller.pZFocus,
                        controller.onPositionXChanged,
                        controller.onPositionYChanged,
                        controller.onPositionZChanged);
                  }),
            ),
            const SizedBox(
              height: 24,
            ),
            SettingsRow(
              spacingRatio: spacingRatio,
              firstChild: Text(
                'Direction : ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              secondChild: const SizedBox(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 112),
              child: StreamBuilder<Double3>(
                  stream: controller.rotationController.stream,
                  builder: (context, snapshot) {
                    return getXYZInputBox(
                        context,
                        controller.rX,
                        controller.rY,
                        controller.rZ,
                        controller.rXFocus,
                        controller.rYFocus,
                        controller.rZFocus,
                        controller.onRotationXChanged,
                        controller.onRotationYChanged,
                        controller.onRotationZChanged);
                  }),
            ),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
