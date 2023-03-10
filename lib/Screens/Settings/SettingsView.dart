import 'package:blue_engine/Screens/Settings/Tabs/Scene/SceneSettingsView.dart';
import 'package:blue_engine/Widgets/MaterialSlidingSegmentedControl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Tabs/Viewport/Views/ViewportSettingsView.dart';

enum SettingTab { viewPort, scene, camera }

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _selectedTab = SettingTab.viewPort;
  var tabs = [
    const ViewportSettingsView(),
    const SceneSettingsView(),
    Container(
      color: CupertinoColors.white,
    ),
    Container(
      color: CupertinoColors.white,
    )
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) => Scaffold(
              body: Center(
                child: Column(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SizedBox(
                          height: 60,
                          child: MaterialSlidingSegmentedControl<SettingTab>(
                            backgroundColor: CupertinoColors.lightBackgroundGray,
                            thumbColor: CupertinoColors.white,
                            groupValue: _selectedTab,
                            // Callback that sets the selected segmented control.
                            onValueChanged: (SettingTab? value) {
                              if (value == null || value == _selectedTab) {
                                return;
                              }
                              setState(() {
                                _selectedTab = value;
                              });
                            },
                            children: const <SettingTab, Widget>{
                              SettingTab.viewPort: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'View Port',
                                  style: TextStyle(
                                      color: CupertinoColors.label, fontSize: 16),
                                ),
                              ),
                              SettingTab.scene: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'Scene',
                                  style: TextStyle(
                                      color: CupertinoColors.label, fontSize: 16),
                                ),
                              ),
                              SettingTab.camera: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'Camera',
                                  style: TextStyle(
                                      color: CupertinoColors.label, fontSize: 16),
                                ),
                              ),
                            },
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight - 80,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: tabs[_selectedTab.index],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }
}
