import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/search_engine_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_adeeinappwebview/flutter_adeeinappwebview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../project_info_popup.dart';

class AccessibilitySettings extends StatefulWidget {
  const AccessibilitySettings({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettings> createState() => _AccessibilitySettingsState();
}

class _AccessibilitySettingsState extends State<AccessibilitySettings> {
  final TextEditingController _customHomePageController =
      TextEditingController();
  final TextEditingController _customUserAgentController =
      TextEditingController();

  @override
  void dispose() {
    _customHomePageController.dispose();
    _customUserAgentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var children = _buildBaseSettings();
    if (browserModel.webViewTabs.isNotEmpty) {
      children.addAll(_buildWebViewTabSettings());
    }

    return ListView(
      children: children,
    );
  }

  List<Widget> _buildBaseSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    var widgets = <Widget>[
      const ListTile(
        title: Text("General Settings"),
        enabled: false,
      ),
      ListTile(
        title: const Text("Search Engine"),
        subtitle: Text(settings.searchEngine.name),
        trailing: DropdownButton<SearchEngineModel>(
          hint: const Text("Search Engine"),
          onChanged: (value) {
            setState(() {
              if (value != null) {
                settings.searchEngine = value;
              }
              browserModel.updateSettings(settings);
            });
          },
          value: settings.searchEngine,
          items: SearchEngines.map((searchEngine) {
            return DropdownMenuItem(
              value: searchEngine,
              child: Text(searchEngine.name),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Home page"),
        subtitle: Text(settings.homePageEnabled
            ? (settings.customUrlHomePage.isEmpty
                ? "ON"
                : settings.customUrlHomePage)
            : "OFF"),
        onTap: () {
          _customHomePageController.text = settings.customUrlHomePage;

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                contentPadding: const EdgeInsets.all(0.0),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    StatefulBuilder(
                      builder: (context, setState) {
                        return SwitchListTile(
                          title: Text(settings.homePageEnabled ? "ON" : "OFF"),
                          value: settings.homePageEnabled,
                          onChanged: (value) {
                            setState(() {
                              settings.homePageEnabled = value;
                              browserModel.updateSettings(settings);
                            });
                          },
                        );
                      },
                    ),
                    StatefulBuilder(builder: (context, setState) {
                      return ListTile(
                        enabled: settings.homePageEnabled,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                onSubmitted: (value) {
                                  setState(() {
                                    settings.customUrlHomePage = value;
                                    browserModel.updateSettings(settings);
                                    Navigator.pop(context);
                                  });
                                },
                                keyboardType: TextInputType.url,
                                decoration: const InputDecoration(
                                    hintText: 'Custom URL Home Page'),
                                controller: _customHomePageController,
                              ),
                            )
                          ],
                        ),
                      );
                    })
                  ],
                ),
              );
            },
          );
        },
      )
    ];

    return widgets;
  }

  List<Widget> _buildWebViewTabSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var webViewController = currentWebViewModel.webViewController;

    var widgets = <Widget>[
      const ListTile(
        title: Text("Current WebView Settings"),
        enabled: false,
      ),
      ListTile(
        title: const Text("Minimum Font Size"),
        subtitle: const Text("Sets the minimum font size."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.settings?.minimumFontSize.toString(),
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.minimumFontSize = int.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.setDefaultTabSettings(currentWebViewModel);
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Block Network Image"),
        subtitle: const Text(
            "Sets whether the WebView should not load image resources from the network (resources accessed via http and https URI schemes)."),
        value: currentWebViewModel.settings?.blockNetworkImage ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.blockNetworkImage = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.setDefaultTabSettings(currentWebViewModel);
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Standard Font Family"),
        subtitle: const Text("Sets the standard font family name."),
        trailing: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.standardFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.standardFontFamily = value;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.setDefaultTabSettings(currentWebViewModel);
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Support Zoom"),
        subtitle: const Text(
            "Sets whether the WebView should not support zooming using its on-screen zoom controls and gestures."),
        value: currentWebViewModel.settings?.supportZoom ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.supportZoom = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.setDefaultTabSettings(currentWebViewModel);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Media Playback Requires User Gesture"),
        subtitle: const Text(
            "Sets whether the WebView should prevent HTML5 audio or video from autoplaying."),
        value: currentWebViewModel.settings?.mediaPlaybackRequiresUserGesture ??
            true,
        onChanged: (value) async {
          currentWebViewModel.settings?.mediaPlaybackRequiresUserGesture =
              value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.setDefaultTabSettings(currentWebViewModel);
          browserModel.save();
          setState(() {});
        },
      )
    ];

    return widgets;
  }
}
