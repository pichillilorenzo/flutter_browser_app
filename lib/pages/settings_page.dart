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
      if (Platform.isAndroid) {
        children.addAll(_buildAndroidWebViewTabSettings());
      } else if (Platform.isIOS) {
        children.addAll(_buildIOSWebViewTabSettings());
      }
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
      ),
      SwitchListTile(
        title: const Text("Debugging Enabled"),
        subtitle: const Text("Enables debugging of web contents loaded into any WebViews of this application. On iOS the debugging mode is always enabled."),
        value: Platform.isAndroid ? settings.debuggingEnabled : true,
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
    ];

    if (Platform.isAndroid) {
      widgets.addAll(<Widget>[
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
        subtitle: const Text("Sets whether the WebView should enable JavaScript."),
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
        subtitle: const Text("Sets whether the WebView should use browser caching."),
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
        title: const Text("Support Zoom"),
        subtitle: const Text("Sets whether the WebView should not support zooming using its on-screen zoom controls and gestures."),
        value: webViewModel.options.crossPlatform.supportZoom,
        onChanged: (value) {
          setState(() {
            webViewModel.options.crossPlatform.supportZoom = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Media Playback Requires User Gesture"),
        subtitle: const Text("Sets whether the WebView should prevent HTML5 audio or video from autoplaying."),
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
        subtitle: const Text("Sets whether the vertical scrollbar should be drawn or no."),
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
        subtitle: const Text("Sets whether the horizontal scrollbar should be drawn or no."),
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

  List<Widget> _buildAndroidWebViewTabSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var webViewModel = browserModel.getCurrentTab().webViewModel;
    var _webViewController = webViewModel.webViewController;

    var widgets = <Widget>[
      ListTile(
        title: const Text("Android WebView Tab Settings"),
        enabled: false,
      ),
      ListTile(
        title: const Text("Text Zoom"),
        subtitle: const Text("Sets the text zoom of the page in percent."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
          initialValue: webViewModel.options.android.textZoom.toString(),
          keyboardType: TextInputType.numberWithOptions(),
          onFieldSubmitted: (value) {
            setState(() {
              webViewModel.options.android.textZoom = int.parse(value);
              _webViewController.setOptions(options: webViewModel.options);
            });
          },
        ),),
      ),
      SwitchListTile(
        title: const Text("Clear Session Cache"),
        subtitle: const Text("Sets whether the WebView should have the session cookie cache cleared before the new window is opened."),
        value: webViewModel.options.android.clearSessionCache,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.clearSessionCache = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Built In Zoom Controls"),
        subtitle: const Text("Sets whether the WebView should use its built-in zoom mechanisms."),
        value: webViewModel.options.android.builtInZoomControls,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.builtInZoomControls = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Display Zoom Controls"),
        subtitle: const Text("Sets whether the WebView should display on-screen zoom controls when using the built-in zoom mechanisms."),
        value: webViewModel.options.android.displayZoomControls,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.displayZoomControls = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Database storage API"),
        subtitle: const Text("Sets whether the Database storage API should be enabled."),
        value: webViewModel.options.android.databaseEnabled,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.databaseEnabled = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("DOM storage API"),
        subtitle: const Text("Sets whether the DOM storage API should be enabled."),
        value: webViewModel.options.android.domStorageEnabled,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.domStorageEnabled = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Use Wide View Port"),
        subtitle: const Text("Sets whether the WebView should enable support for the \"viewport\" HTML meta tag or should use a wide viewport."),
        value: webViewModel.options.android.useWideViewPort,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.useWideViewPort = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      ListTile(
        title: const Text("Mixed Content Mode"),
        subtitle: const Text("Configures the WebView's behavior when a secure origin attempts to load a resource from an insecure origin."),
        trailing: DropdownButton<int>(
          hint: Text("MixedContentMode"),
          onChanged: (value) {
            setState(() {
              webViewModel.options.android.mixedContentMode = AndroidMixedContentMode.fromValue(value);
              _webViewController.setOptions(options: webViewModel.options);
            });
          },
          value: webViewModel.options.android.mixedContentMode.toValue(),
          items: [0,1,2].map((mixedContentMode) {
            return DropdownMenuItem<int>(
              value: mixedContentMode,
              child: Text(AndroidMixedContentMode.fromValue(mixedContentMode).toString(), style: TextStyle(fontSize: 12.5),),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Allow Content Access"),
        subtitle: const Text("Enables or disables content URL access within WebView. Content URL access allows WebView to load content from a content provider installed in the system."),
        value: webViewModel.options.android.allowContentAccess,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.allowContentAccess = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Allow File Access"),
        subtitle: const Text("Enables or disables file access within WebView. Note that this enables or disables file system access only."),
        value: webViewModel.options.android.allowFileAccess,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.allowFileAccess = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Allow File Access From File URLs"),
        subtitle: const Text("Sets whether JavaScript running in the context of a file scheme URL should be allowed to access content from other file scheme URLs."),
        value: webViewModel.options.android.allowFileAccessFromFileURLs,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.allowFileAccessFromFileURLs = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Allow Universal Access From File URLs"),
        subtitle: const Text("Sets whether JavaScript running in the context of a file scheme URL should be allowed to access content from any origin."),
        value: webViewModel.options.android.allowUniversalAccessFromFileURLs,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.allowUniversalAccessFromFileURLs = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      ListTile(
        title: const Text("App Cache Path"),
        subtitle: const Text("Sets the path to the Application Caches files. In order for the Application Caches API to be enabled, this option must be set a path to which the application can write."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: webViewModel.options.android.appCachePath,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.appCachePath = value.trim();
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      SwitchListTile(
        title: const Text("Block Network Image"),
        subtitle: const Text("Sets whether the WebView should not load image resources from the network (resources accessed via http and https URI schemes)."),
        value: webViewModel.options.android.blockNetworkImage,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.blockNetworkImage = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Block Network Loads"),
        subtitle: const Text("Sets whether the WebView should not load resources from the network."),
        value: webViewModel.options.android.blockNetworkLoads,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.blockNetworkLoads = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
    ];

    return widgets;
  }

  List<Widget> _buildIOSWebViewTabSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var webViewModel = browserModel.getCurrentTab().webViewModel;
    var _webViewController = webViewModel.webViewController;

    var widgets = <Widget>[
      ListTile(
        title: const Text("iOS WebView Tab Settings"),
        enabled: false,
      ),
    ];

    return widgets;
  }

}