import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/pages/settings/android_settings.dart';
import 'package:flutter_browser/pages/settings/cross_platform_settings.dart';
import 'package:flutter_browser/pages/settings/ios_settings.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../../custom_popup_menu_item.dart';

class PopupSettingsMenuActions {
  // ignore: constant_identifier_names
  static const String RESET_BROWSER_SETTINGS = "Reset Browser Settings";
  // ignore: constant_identifier_names
  static const String RESET_WEBVIEW_SETTINGS = "Reset WebView Settings";

  static const List<String> choices = <String>[
    RESET_BROWSER_SETTINGS,
    RESET_WEBVIEW_SETTINGS,
  ];
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
                onTap: (value) {
                  FocusScope.of(context).unfocus();
                },
                tabs: const [
                  Tab(
                    text: "Cross-Platform",
                    icon: SizedBox(
                      width: 25,
                      height: 25,
                      child: CircleAvatar(
                        backgroundImage: AssetImage("assets/icon/icon.png"),
                      ),
                    ),
                  ),
                  Tab(
                    text: "Android",
                    icon: Icon(
                      Icons.android,
                      color: Colors.green,
                    ),
                  ),
                  Tab(
                    text: "iOS",
                    icon: Icon(AntDesign.apple1),
                  ),
                ]),
            title: const Text(
              "Settings",
            ),
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: _popupMenuChoiceAction,
                itemBuilder: (context) {
                  var items = [
                    CustomPopupMenuItem<String>(
                      enabled: true,
                      value: PopupSettingsMenuActions.RESET_BROWSER_SETTINGS,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(PopupSettingsMenuActions
                                .RESET_BROWSER_SETTINGS),
                            Icon(
                              Foundation.web,
                              color: Colors.black,
                            )
                          ]),
                    ),
                    CustomPopupMenuItem<String>(
                      enabled: true,
                      value: PopupSettingsMenuActions.RESET_WEBVIEW_SETTINGS,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(PopupSettingsMenuActions
                                .RESET_WEBVIEW_SETTINGS),
                            Icon(
                              MaterialIcons.web,
                              color: Colors.black,
                            )
                          ]),
                    )
                  ];

                  return items;
                },
              )
            ],
          ),
          body: const TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              CrossPlatformSettings(),
              AndroidSettings(),
              IOSSettings(),
            ],
          ),
        ));
  }

  void _popupMenuChoiceAction(String choice) async {
    switch (choice) {
      case PopupSettingsMenuActions.RESET_BROWSER_SETTINGS:
        var browserModel = Provider.of<BrowserModel>(context, listen: false);
        setState(() {
          browserModel.updateSettings(BrowserSettings());
          browserModel.save();
        });
        break;
      case PopupSettingsMenuActions.RESET_WEBVIEW_SETTINGS:
        var browserModel = Provider.of<BrowserModel>(context, listen: false);
        browserModel.getSettings();
        var currentWebViewModel =
            Provider.of<WebViewModel>(context, listen: false);
        var webViewController = currentWebViewModel.webViewController;
        await webViewController?.setSettings(
            settings: InAppWebViewSettings(
                incognito: currentWebViewModel.isIncognitoMode,
                useOnDownloadStart: true,
                useOnLoadResource: true,
                safeBrowsingEnabled: true,
                allowsLinkPreview: false,
                isFraudulentWebsiteWarningEnabled: true));
        currentWebViewModel.settings = await webViewController?.getSettings();
        browserModel.save();
        setState(() {});
        break;
    }
  }
}
