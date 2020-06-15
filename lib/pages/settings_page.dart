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
          hint: Text("Search Engine"),
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
          hint: Text("Mixed Content Mode"),
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
      ListTile(
        title: const Text("Cache Mode"),
        subtitle: const Text("Overrides the way the cache is used. The way the cache is used is based on the navigation type."),
        trailing: DropdownButton<int>(
          hint: Text("Cache Mode"),
          onChanged: (value) {
            setState(() {
              webViewModel.options.android.cacheMode = AndroidCacheMode.fromValue(value);
              _webViewController.setOptions(options: webViewModel.options);
            });
          },
          value: webViewModel.options.android.cacheMode?.toValue(),
          items: [0,1,2,3].map((cacheMode) {
            return DropdownMenuItem<int>(
              value: cacheMode,
              child: Text(AndroidCacheMode.fromValue(cacheMode).toString(), style: TextStyle(fontSize: 12.5),),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Cursive Font Family"),
        subtitle: const Text("Sets the cursive font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: webViewModel.options.android.cursiveFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.cursiveFontFamily = value;
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      ListTile(
        title: const Text("Default Fixed Font Size"),
        subtitle: const Text("Sets the default fixed font size."),
        trailing: Container(
          width: 50,
          child: TextFormField(
            initialValue: webViewModel.options.android.defaultFixedFontSize.toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.defaultFixedFontSize = int.parse(value);
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      ListTile(
        title: const Text("Default Font Size"),
        subtitle: const Text("Sets the default font size."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: webViewModel.options.android.defaultFontSize.toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.defaultFontSize = int.parse(value);
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      ListTile(
        title: const Text("Default Text Encoding Name"),
        subtitle: const Text("Sets the default text encoding name to use when decoding html pages."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: webViewModel.options.android.defaultTextEncodingName,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.defaultTextEncodingName = value;
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      ListTile(
        title: const Text("Disabled Action Mode Menu Items"),
        subtitle: const Text("Disables the action mode menu items according to menuItems flag."),
        trailing: DropdownButton<int>(
          hint: Text("Action Mode Menu Items"),
          onChanged: (value) {
            setState(() {
              webViewModel.options.android.disabledActionModeMenuItems = AndroidActionModeMenuItem.fromValue(value);
              _webViewController.setOptions(options: webViewModel.options);
            });
          },
          value: webViewModel.options.android.disabledActionModeMenuItems.toValue(),
          items: [0,1,2,4].map((actionModeMenuItem) {
            return DropdownMenuItem<int>(
              value: actionModeMenuItem,
              child: Text(AndroidActionModeMenuItem.fromValue(actionModeMenuItem).toString(), style: TextStyle(fontSize: 12.5),),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Fantasy Font Family"),
        subtitle: const Text("Sets the fantasy font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: webViewModel.options.android.fantasyFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.fantasyFontFamily = value;
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      ListTile(
        title: const Text("Fixed Font Family"),
        subtitle: const Text("Sets the fixed font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: webViewModel.options.android.fixedFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.fixedFontFamily = value;
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      ListTile(
        title: const Text("Force Dark"),
        subtitle: const Text("Set the force dark mode for this WebView."),
        trailing: DropdownButton<int>(
          hint: Text("Force Dark"),
          onChanged: (value) {
            setState(() {
              webViewModel.options.android.forceDark = AndroidForceDark.fromValue(value);
              _webViewController.setOptions(options: webViewModel.options);
            });
          },
          value: webViewModel.options.android.forceDark.toValue(),
          items: [0,1,2].map((forceDark) {
            return DropdownMenuItem<int>(
              value: forceDark,
              child: Text(AndroidForceDark.fromValue(forceDark).toString(), style: TextStyle(fontSize: 12.5),),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Geolocation Enabled"),
        subtitle: const Text("Sets whether Geolocation API is enabled."),
        value: webViewModel.options.android.geolocationEnabled,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.geolocationEnabled = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      ListTile(
        title: const Text("Layout Algorithm"),
        subtitle: const Text("Sets the underlying layout algorithm. This will cause a re-layout of the WebView."),
        trailing: DropdownButton<String>(
          hint: Text("Layout Algorithm"),
          onChanged: (value) {
            setState(() {
              webViewModel.options.android.layoutAlgorithm = AndroidLayoutAlgorithm.fromValue(value);
              _webViewController.setOptions(options: webViewModel.options);
            });
          },
          value: webViewModel.options.android.layoutAlgorithm.toValue(),
          items: ["NORMAL", "TEXT_AUTOSIZING", "NARROW_COLUMNS"].map((layoutAlgorithm) {
            return DropdownMenuItem<String>(
              value: layoutAlgorithm,
              child: Text(AndroidLayoutAlgorithm.fromValue(layoutAlgorithm).toString(), style: TextStyle(fontSize: 12.5),),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Load With Overview Mode"),
        subtitle: const Text("Sets whether the WebView loads pages in overview mode, that is, zooms out the content to fit on screen by width."),
        value: webViewModel.options.android.loadWithOverviewMode,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.loadWithOverviewMode = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Loads Images Automatically"),
        subtitle: const Text("Sets whether the WebView should load image resources. Note that this method controls loading of all images, including those embedded using the data URI scheme."),
        value: webViewModel.options.android.loadsImagesAutomatically,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.loadsImagesAutomatically = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      ListTile(
        title: const Text("Minimum Logical Font Size"),
        subtitle: const Text("Sets the minimum logical font size."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: webViewModel.options.android.minimumLogicalFontSize.toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.minimumLogicalFontSize = int.parse(value);
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      ListTile(
        title: const Text("Initial Scale"),
        subtitle: const Text("Sets the initial scale for this WebView. 0 means default."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: webViewModel.options.android.initialScale.toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.initialScale = int.parse(value);
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      SwitchListTile(
        title: const Text("Need Initial Focus"),
        subtitle: const Text("Tells the WebView whether it needs to set a node."),
        value: webViewModel.options.android.needInitialFocus,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.needInitialFocus = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Offscreen Pre Raster"),
        subtitle: const Text("Sets whether this WebView should raster tiles when it is offscreen but attached to a window."),
        value: webViewModel.options.android.offscreenPreRaster,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.offscreenPreRaster = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      ListTile(
        title: const Text("Sans-Serif Font Family"),
        subtitle: const Text("Sets the sans-serif font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: webViewModel.options.android.sansSerifFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.sansSerifFontFamily = value;
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      ListTile(
        title: const Text("Serif Font Family"),
        subtitle: const Text("Sets the serif font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: webViewModel.options.android.serifFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.serifFontFamily = value;
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      ListTile(
        title: const Text("Standard Font Family"),
        subtitle: const Text("Sets the standard font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: webViewModel.options.android.standardFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.standardFontFamily = value;
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      SwitchListTile(
        title: const Text("Save Form Data"),
        subtitle: const Text("Sets whether the WebView should save form data. In Android O, the platform has implemented a fully functional Autofill feature to store form data."),
        value: webViewModel.options.android.saveFormData,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.saveFormData = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Third Party Cookies Enabled"),
        subtitle: const Text("Sets whether the Webview should enable third party cookies."),
        value: webViewModel.options.android.thirdPartyCookiesEnabled,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.thirdPartyCookiesEnabled = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Hardware Acceleration"),
        subtitle: const Text("Sets whether the Webview should enable Hardware Acceleration."),
        value: webViewModel.options.android.hardwareAcceleration,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.hardwareAcceleration = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      SwitchListTile(
        title: const Text("Support Multiple Windows"),
        subtitle: const Text("Sets whether the WebView whether supports multiple windows."),
        value: webViewModel.options.android.supportMultipleWindows,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.supportMultipleWindows = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      ListTile(
        title: const Text("Over Scroll Mode"),
        subtitle: const Text("Sets the WebView's over-scroll mode."),
        trailing: DropdownButton<int>(
          hint: Text("Over Scroll Mode"),
          onChanged: (value) {
            setState(() {
              webViewModel.options.android.overScrollMode = AndroidOverScrollMode.fromValue(value);
              _webViewController.setOptions(options: webViewModel.options);
            });
          },
          value: webViewModel.options.android.overScrollMode.toValue(),
          items: [0,1,2].map((overScrollMode) {
            return DropdownMenuItem<int>(
              value: overScrollMode,
              child: Text(AndroidOverScrollMode.fromValue(overScrollMode).toString(), style: TextStyle(fontSize: 12.5),),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Network Available"),
        subtitle: const Text("Informs WebView of the network state."),
        value: webViewModel.options.android.networkAvailable ?? true,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.networkAvailable = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      ListTile(
        title: const Text("Scroll Bar Style"),
        subtitle: const Text("Specify the style of the scrollbars."),
        trailing: DropdownButton<int>(
          hint: Text("Scroll Bar Style"),
          onChanged: (value) {
            setState(() {
              webViewModel.options.android.scrollBarStyle = AndroidScrollBarStyle.fromValue(value);
              _webViewController.setOptions(options: webViewModel.options);
            });
          },
          value: webViewModel.options.android.scrollBarStyle?.toValue(),
          items: [0,16777216,33554432,50331648].map((scrollBarStyle) {
            return DropdownMenuItem<int>(
              value: scrollBarStyle,
              child: Text(AndroidScrollBarStyle.fromValue(scrollBarStyle).toString(), style: TextStyle(fontSize: 12.5),),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Vertical Scrollbar Position"),
        subtitle: const Text("Set the position of the vertical scroll bar."),
        trailing: DropdownButton<int>(
          hint: Text("Vertical Scrollbar Position"),
          onChanged: (value) {
            setState(() {
              webViewModel.options.android.verticalScrollbarPosition = AndroidVerticalScrollbarPosition.fromValue(value);
              _webViewController.setOptions(options: webViewModel.options);
            });
          },
          value: webViewModel.options.android.verticalScrollbarPosition.toValue(),
          items: [0,1,2].map((verticalScrollbarPosition) {
            return DropdownMenuItem<int>(
              value: verticalScrollbarPosition,
              child: Text(AndroidVerticalScrollbarPosition.fromValue(verticalScrollbarPosition).toString(), style: TextStyle(fontSize: 12.5),),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Scroll Bar Default Delay Before Fade"),
        subtitle: const Text("Defines the delay in milliseconds that a scrollbar waits before fade out."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: webViewModel.options.android.scrollBarDefaultDelayBeforeFade.toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.scrollBarDefaultDelayBeforeFade = int.parse(value);
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
      ),
      SwitchListTile(
        title: const Text("Scrollbar Fading Enabled"),
        subtitle: const Text("Define whether scrollbars will fade when the view is not scrolling."),
        value: webViewModel.options.android.scrollbarFadingEnabled,
        onChanged: (value) {
          setState(() {
            webViewModel.options.android.scrollbarFadingEnabled = value;
            _webViewController.setOptions(options: webViewModel.options);
          });
        },
      ),
      ListTile(
        title: const Text("Scroll Bar Fade Duration"),
        subtitle: const Text("Define the scrollbar fade duration in milliseconds."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: webViewModel.options.android.scrollBarFadeDuration.toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) {
              setState(() {
                webViewModel.options.android.scrollBarFadeDuration = int.parse(value);
                _webViewController.setOptions(options: webViewModel.options);
              });
            },
          ),),
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