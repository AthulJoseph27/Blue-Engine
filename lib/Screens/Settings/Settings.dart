import 'package:flutter/cupertino.dart';

enum SettingTab { viewPort, scene, camera }

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _selectedTab = SettingTab.viewPort;
  var tabs = [
    Container(
      color: CupertinoColors.activeBlue,
    ),
    Container(
      color: CupertinoColors.activeOrange,
    ),
    Container(
      color: CupertinoColors.destructiveRed,
    )
  ];
  var firstChildIndex = 0;
  var secondChildIndex = 1;
  var crossFadeState = CrossFadeState.showFirst;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) => CupertinoPageScaffold(
              child: Center(
                child: Column(
                  children: [
                    Center(
                      child: SizedBox(
                        height: 120,
                        child: CupertinoSlidingSegmentedControl<SettingTab>(
                          backgroundColor: CupertinoColors.lightBackgroundGray,
                          thumbColor: CupertinoColors.white,
                          groupValue: _selectedTab,
                          // Callback that sets the selected segmented control.
                          onValueChanged: (SettingTab? value) {
                            if (value == null || value == _selectedTab) {
                              return;
                            }

                            setState(() {
                              if (crossFadeState == CrossFadeState.showFirst) {
                                secondChildIndex = value.index;
                                crossFadeState = CrossFadeState.showSecond;
                              } else {
                                secondChildIndex = firstChildIndex;
                                firstChildIndex = value.index;
                                crossFadeState = CrossFadeState.showFirst;
                              }

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
                    Center(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight - 120,
                        child: AnimatedCrossFade(
                          firstChild: tabs[firstChildIndex],
                          secondChild: tabs[secondChildIndex],
                          crossFadeState: crossFadeState,
                          duration: const Duration(milliseconds: 500),
                          firstCurve: Curves.easeIn,
                          secondCurve: Curves.easeIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }
}
