import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/search_engine_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../project_info_popup.dart';

class CrossPlatformSettings extends StatefulWidget {
  const CrossPlatformSettings({Key? key}) : super(key: key);

  @override
  State<CrossPlatformSettings> createState() => _CrossPlatformSettingsState();
}

class _CrossPlatformSettingsState extends State<CrossPlatformSettings> {
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
      ),
      FutureBuilder(
        future: InAppWebViewController.getDefaultUserAgent(),
        builder: (context, snapshot) {
          var deafultUserAgent = "";
          if (snapshot.hasData) {
            deafultUserAgent = snapshot.data as String;
          }

          return ListTile(
            title: const Text("Default User Agent"),
            subtitle: Text(deafultUserAgent),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: deafultUserAgent));
            },
          );
        },
      ),
      SwitchListTile(
        title: const Text("Debugging Enabled"),
        subtitle: const Text(
            "Enables debugging of web contents loaded into any WebViews of this application. On iOS the debugging mode is always enabled."),
        value: Platform.isAndroid ? settings.debuggingEnabled : true,
        onChanged: (value) {
          setState(() {
            settings.debuggingEnabled = value;
            browserModel.updateSettings(settings);
            if (browserModel.webViewTabs.isNotEmpty) {
              var webViewModel = browserModel.getCurrentTab()?.webViewModel;
              if (Platform.isAndroid) {
                AndroidInAppWebViewController.setWebContentsDebuggingEnabled(
                    settings.debuggingEnabled);
              }
              webViewModel?.webViewController?.setOptions(
                  options: webViewModel.options ?? InAppWebViewGroupOptions());
              browserModel.save();
            }
          });
        },
      ),
      FutureBuilder(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          String packageDescription = "";
          if (snapshot.hasData) {
            PackageInfo packageInfo = snapshot.data as PackageInfo;
            packageDescription =
                "Package Name: ${packageInfo.packageName}\nVersion: ${packageInfo.version}\nBuild Number: ${packageInfo.buildNumber}";
          }
          return ListTile(
            title: const Text("Flutter Browser Package Info"),
            subtitle: Text(packageDescription),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: packageDescription));
            },
          );
        },
      ),
      ListTile(
        leading: Container(
          height: 35,
          width: 35,
          margin: const EdgeInsets.only(top: 6.0, left: 6.0),
          child: const CircleAvatar(
              backgroundImage: AssetImage("assets/icon/icon.png")),
        ),
        title: const Text("Flutter InAppWebView Project"),
        subtitle: const Text(
            "https://github.com/pichillilorenzo/flutter_inappwebview"),
        trailing: const Icon(Icons.arrow_forward),
        onLongPress: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return const ProjectInfoPopup();
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
        onTap: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return const ProjectInfoPopup();
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      )
    ];

    if (Platform.isAndroid) {
      widgets.addAll(<Widget>[
        FutureBuilder(
          future: AndroidInAppWebViewController.getCurrentWebViewPackage(),
          builder: (context, snapshot) {
            String packageDescription = "";
            if (snapshot.hasData) {
              AndroidWebViewPackageInfo packageInfo =
                  snapshot.data as AndroidWebViewPackageInfo;
              packageDescription =
                  "${packageInfo.packageName ?? ""} - ${packageInfo.versionName ?? ""}";
            }
            return ListTile(
              title: const Text("WebView Package Info"),
              subtitle: Text(packageDescription),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: packageDescription));
              },
            );
          },
        )
      ]);
    }

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
      SwitchListTile(
        title: const Text("JavaScript Enabled"),
        subtitle:
            const Text("Sets whether the WebView should enable JavaScript."),
        value: currentWebViewModel.options?.crossPlatform.javaScriptEnabled ??
            true,
        onChanged: (value) async {
          currentWebViewModel.options?.crossPlatform.javaScriptEnabled = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Cache Enabled"),
        subtitle:
            const Text("Sets whether the WebView should use browser caching."),
        value: currentWebViewModel.options?.crossPlatform.cacheEnabled ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.crossPlatform.cacheEnabled = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      StatefulBuilder(
        builder: (context, setState) {
          return ListTile(
            title: const Text("Custom User Agent"),
            subtitle: Text(currentWebViewModel
                        .options?.crossPlatform.userAgent.isNotEmpty ??
                    false
                ? currentWebViewModel.options!.crossPlatform.userAgent
                : "Set a custom user agent ..."),
            onTap: () {
              _customUserAgentController.text =
                  currentWebViewModel.options?.crossPlatform.userAgent ?? "";

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    contentPadding: const EdgeInsets.all(0.0),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  onSubmitted: (value) async {
                                    currentWebViewModel.options?.crossPlatform
                                        .userAgent = value;
                                    webViewController?.setOptions(
                                        options: currentWebViewModel.options ??
                                            InAppWebViewGroupOptions());
                                    currentWebViewModel.options =
                                        await webViewController?.getOptions();
                                    browserModel.save();
                                    setState(() {
                                      Navigator.pop(context);
                                    });
                                  },
                                  decoration: const InputDecoration(
                                      hintText: 'Custom User Agent'),
                                  controller: _customUserAgentController,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.go,
                                  maxLines: null,
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      SwitchListTile(
        title: const Text("Support Zoom"),
        subtitle: const Text(
            "Sets whether the WebView should not support zooming using its on-screen zoom controls and gestures."),
        value: currentWebViewModel.options?.crossPlatform.supportZoom ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.crossPlatform.supportZoom = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Media Playback Requires User Gesture"),
        subtitle: const Text(
            "Sets whether the WebView should prevent HTML5 audio or video from autoplaying."),
        value: currentWebViewModel
                .options?.crossPlatform.mediaPlaybackRequiresUserGesture ??
            true,
        onChanged: (value) async {
          currentWebViewModel
              .options?.crossPlatform.mediaPlaybackRequiresUserGesture = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Vertical ScrollBar Enabled"),
        subtitle: const Text(
            "Sets whether the vertical scrollbar should be drawn or not."),
        value: currentWebViewModel
                .options?.crossPlatform.verticalScrollBarEnabled ??
            true,
        onChanged: (value) async {
          currentWebViewModel.options?.crossPlatform.verticalScrollBarEnabled =
              value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Horizontal ScrollBar Enabled"),
        subtitle: const Text(
            "Sets whether the horizontal scrollbar should be drawn or not."),
        value: currentWebViewModel
                .options?.crossPlatform.horizontalScrollBarEnabled ??
            true,
        onChanged: (value) async {
          currentWebViewModel
              .options?.crossPlatform.horizontalScrollBarEnabled = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Disable Vertical Scroll"),
        subtitle: const Text(
            "Sets whether vertical scroll should be enabled or not."),
        value:
            currentWebViewModel.options?.crossPlatform.disableVerticalScroll ??
                false,
        onChanged: (value) async {
          currentWebViewModel.options?.crossPlatform.disableVerticalScroll =
              value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Disable Horizontal Scroll"),
        subtitle: const Text(
            "Sets whether horizontal scroll should be enabled or not."),
        value: currentWebViewModel
                .options?.crossPlatform.disableHorizontalScroll ??
            false,
        onChanged: (value) async {
          currentWebViewModel.options?.crossPlatform.disableHorizontalScroll =
              value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Disable Context Menu"),
        subtitle:
            const Text("Sets whether context menu should be enabled or not."),
        value: currentWebViewModel.options?.crossPlatform.disableContextMenu ??
            false,
        onChanged: (value) async {
          currentWebViewModel.options?.crossPlatform.disableContextMenu = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Minimum Font Size"),
        subtitle: const Text("Sets the minimum font size."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel
                .options?.crossPlatform.minimumFontSize
                .toString(),
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.crossPlatform.minimumFontSize =
                  int.parse(value);
              webViewController?.setOptions(
                  options: currentWebViewModel.options ??
                      InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await webViewController?.getOptions();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Allow File Access From File URLs"),
        subtitle: const Text(
            "Sets whether JavaScript running in the context of a file scheme URL should be allowed to access content from other file scheme URLs."),
        value: currentWebViewModel
                .options?.crossPlatform.allowFileAccessFromFileURLs ??
            false,
        onChanged: (value) async {
          currentWebViewModel
              .options?.crossPlatform.allowFileAccessFromFileURLs = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allow Universal Access From File URLs"),
        subtitle: const Text(
            "Sets whether JavaScript running in the context of a file scheme URL should be allowed to access content from any origin."),
        value: currentWebViewModel
                .options?.crossPlatform.allowUniversalAccessFromFileURLs ??
            false,
        onChanged: (value) async {
          currentWebViewModel
              .options?.crossPlatform.allowUniversalAccessFromFileURLs = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
    ];

    return widgets;
  }
}
