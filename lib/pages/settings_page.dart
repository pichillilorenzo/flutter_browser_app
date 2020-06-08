import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/search_engine_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  TextEditingController _customHomePageController = TextEditingController();
  TextEditingController _customUserAgentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    var children = _buildBaseSettings();
    if (browserModel.webViewTabs.length > 0) {
      children.addAll(_buildWebViewTabSettings());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
        ),
      ),
      body: ListView(
        children: children,
      ),
    );
  }

  List<Widget> _buildBaseSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    var widgets = <Widget>[
      ListTile(
        title: const Text("Base Settings"),
        enabled: false,
      ),
      ListTile(
        title: const Text("Search Engine"),
        subtitle: Text(settings.searchEngine.name),
        trailing: DropdownButton<SearchEngineModel>(
          hint: Text("Choose your Search Engine"),
          onChanged: (value) {
            setState(() {
              settings.searchEngine = value;
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
        subtitle: Text(settings.homePageEnabled ? (settings.customUrlHomePage.isEmpty ? "ON" : settings.customUrlHomePage) : "OFF"),
        onTap: () {
          _customHomePageController.text = settings.customUrlHomePage;

          showDialog(context: context,
            builder: (context) {
              return AlertDialog(
                contentPadding: EdgeInsets.all(0.0),
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
                    StatefulBuilder(
                      builder: (context, setState) {
                        return ListTile(
                          enabled: settings.homePageEnabled,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  onSubmitted: (value) {
                                    setState(() {
                                      settings.customUrlHomePage = value ?? "";
                                      browserModel.updateSettings(settings);
                                      Navigator.pop(context);
                                    });
                                  },
                                  keyboardType: TextInputType.url,
                                  decoration: InputDecoration(
                                      hintText: 'Custom URL Home Page'
                                  ),
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
            deafultUserAgent = snapshot.data;
          }

          return ListTile(
            title: const Text("Default User Agent"),
            subtitle: Text(deafultUserAgent),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: deafultUserAgent));
            },
          );
        },
      )
    ];

    if (Platform.isAndroid) {
      widgets.addAll(<Widget>[
          SwitchListTile(
            title: const Text("Debugging Enabled"),
            value: settings.debuggingEnabled,
            onChanged: (value) {
              setState(() {
                settings.debuggingEnabled = value;
                browserModel.updateSettings(settings);
                if (browserModel.webViewTabs.length > 0) {
                  var webViewModel = browserModel.getCurrentTab().webViewModel;
                  webViewModel.options.crossPlatform.debuggingEnabled = value;
                  webViewModel.webViewController.setOptions(options: webViewModel.options);
                }
              });
            },
          ),
          FutureBuilder(
            future: AndroidInAppWebViewController.getCurrentWebViewPackage(),
            builder: (context, snapshot) {
              String packageDescription = "";
              if (snapshot.hasData) {
                AndroidWebViewPackageInfo packageInfo = snapshot.data;
                packageDescription = packageInfo.packageName + " - " + packageInfo.versionName;
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
        ]
      );
    }

    return widgets;
  }

  List<Widget> _buildWebViewTabSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var webViewModel = browserModel.getCurrentTab().webViewModel;
    var _webViewController = webViewModel.webViewController;

    var widgets = <Widget>[
      ListTile(
        title: const Text("WebView Tab Settings"),
        enabled: false,
      ),
      SwitchListTile(
        title: const Text("JavaScript Enabled"),
        value: webViewModel.options.crossPlatform.javaScriptEnabled,
        onChanged: (value) {
          setState(() {
            webViewModel.options.crossPlatform.javaScriptEnabled = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Cache Enabled"),
        value: webViewModel.options.crossPlatform.cacheEnabled,
        onChanged: (value) {
          setState(() {
            webViewModel.options.crossPlatform.cacheEnabled = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      StatefulBuilder(
        builder: (context, setState) {
          return ListTile(
              title: const Text("Custom User Agent"),
              subtitle: Text(webViewModel.options.crossPlatform.userAgent.isNotEmpty ? webViewModel.options.crossPlatform.userAgent : "Set a custom user agent ..."),
              onTap: () {
                _customUserAgentController.text = webViewModel.options.crossPlatform.userAgent;

                showDialog(context: context,
                  builder: (context) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.all(0.0),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Expanded(
                                  child: TextField(
                                    onSubmitted: (value) {
                                      setState(() {
                                        webViewModel.options.crossPlatform.userAgent = value ?? "";
                                        _webViewController.setOptions(options: webViewModel.options);
                                        Navigator.pop(context);
                                      });
                                    },
                                    decoration: InputDecoration(
                                        hintText: 'Custom User Agent'
                                    ),
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
        title: const Text("Media Playback Requires User Gesture"),
        value: webViewModel.options.crossPlatform.mediaPlaybackRequiresUserGesture,
        onChanged: (value) {
          setState(() {
            webViewModel.options.crossPlatform.mediaPlaybackRequiresUserGesture = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Vertical ScrollBar Enabled"),
        value: webViewModel.options.crossPlatform.verticalScrollBarEnabled,
        onChanged: (value) {
          setState(() {
            webViewModel.options.crossPlatform.verticalScrollBarEnabled = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Horizontal ScrollBar Enabled"),
        value: webViewModel.options.crossPlatform.horizontalScrollBarEnabled,
        onChanged: (value) {
          setState(() {
            webViewModel.options.crossPlatform.horizontalScrollBarEnabled = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
    ];

    if (Platform.isAndroid) {

    } else if (Platform.isIOS) {

    }

    return widgets;
  }

}