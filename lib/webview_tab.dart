import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import 'javascript_console_result.dart';
import 'long_press_alert_dialog.dart';
import 'models/browser_model.dart';

class WebViewTab extends StatefulWidget {
  WebViewTab({Key key, this.webViewModel}) : super(key: key);

  final WebViewModel webViewModel;

  @override
  _WebViewTabState createState() => _WebViewTabState();
}

class _WebViewTabState extends State<WebViewTab> with WidgetsBindingObserver {
  InAppWebViewController _webViewController;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _webViewController = null;
    widget.webViewModel.webViewController = null;

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_webViewController != null) {
      if (state == AppLifecycleState.paused) {
        _webViewController.pauseTimers();
        if (Platform.isAndroid) {
          _webViewController.android.pause();
        }
      } else {
        _webViewController.resumeTimers();
        if (Platform.isAndroid) {
          _webViewController.android.resume();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);

    return InAppWebView(
          initialUrl: widget.webViewModel.url,
          initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                  debuggingEnabled: settings.debuggingEnabled,
                  incognito: widget.webViewModel.isIncognitoMode,
                  useOnDownloadStart: true,
                  useOnLoadResource: true),
            android: AndroidInAppWebViewOptions(
              safeBrowsingEnabled: true
            ),
            ios: IOSInAppWebViewOptions(
              allowsLinkPreview: false,
              isFraudulentWebsiteWarningEnabled: true
            )
          ),
          onWebViewCreated: (controller) async {
            _webViewController = controller;
            widget.webViewModel.webViewController = controller;

            if (Platform.isAndroid) {
              controller.android.startSafeBrowsing();
            }

            widget.webViewModel.options = await controller.getOptions();

            if (isCurrentTab(currentWebViewModel)) {
              currentWebViewModel.updateWithValue(widget.webViewModel);
            }
          },
          onLoadStart: (controller, url) async {
            widget.webViewModel.isSecure = Util.urlIsSecure(url);
            widget.webViewModel.url = url;
            widget.webViewModel.loaded = false;
            widget.webViewModel.setLoadedResources([]);
            widget.webViewModel.setJavaScriptConsoleResults([]);

            if (isCurrentTab(currentWebViewModel)) {
              currentWebViewModel.updateWithValue(widget.webViewModel);
            }
          },
          onLoadStop: (controller, url) async {
            var sslCertificateFuture = controller.getCertificate();
            var titleFuture = _webViewController?.getTitle();
            var faviconsFuture = _webViewController?.getFavicons();

            var sslCertificate = await sslCertificateFuture;
            if (sslCertificate == null && !Util.isLocalizedContent(url)) {
              widget.webViewModel.isSecure = false;
            }

            widget.webViewModel.url = url;
            widget.webViewModel.title = await titleFuture;
            widget.webViewModel.favicon = null;
            widget.webViewModel.loaded = true;

            List<Favicon> favicons = await faviconsFuture;
            if (favicons != null && favicons.isNotEmpty) {
              for (var fav in favicons) {
                if (widget.webViewModel.favicon == null) {
                  widget.webViewModel.favicon = fav;
                } else {
                  if ((widget.webViewModel.favicon.width == null &&
                      !widget.webViewModel.favicon.url
                          .endsWith("favicon.ico")) ||
                      (fav.width != null &&
                          widget.webViewModel.favicon.width != null &&
                          fav.width > widget.webViewModel.favicon.width)) {
                    widget.webViewModel.favicon = fav;
                  }
                }
              }
            }

            if (isCurrentTab(currentWebViewModel)) {
              currentWebViewModel.updateWithValue(widget.webViewModel);
            }
          },
          onProgressChanged: (controller, progress) {
            widget.webViewModel.progress = progress / 100;

            if (isCurrentTab(currentWebViewModel)) {
              currentWebViewModel.updateWithValue(widget.webViewModel);
            }
          },
          onUpdateVisitedHistory: (controller, url, androidIsReload) async {
            widget.webViewModel.url = url;
            widget.webViewModel.title = await _webViewController?.getTitle();

            if (isCurrentTab(currentWebViewModel)) {
              currentWebViewModel.updateWithValue(widget.webViewModel);
            }
          },
          onLongPressHitTestResult: (controller, hitTestResult) async {
            if (LongPressAlertDialog.HIT_TEST_RESULT_SUPPORTED
                .contains(hitTestResult.type)) {

              var requestFocusNodeHrefResult = await controller.requestFocusNodeHref();

              showDialog(
                context: context,
                builder: (context) {
                  return LongPressAlertDialog(
                    webViewModel: widget.webViewModel,
                    hitTestResult: hitTestResult,
                    requestFocusNodeHrefResult: requestFocusNodeHrefResult,
                  );
                },
              );
            }
          },
          onConsoleMessage: (controller, consoleMessage) {
            Color consoleTextColor = Colors.black;
            Color consoleBackgroundColor = Colors.transparent;
            IconData consoleIconData;
            Color consoleIconColor;
            if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
              consoleTextColor = Colors.red;
              consoleIconData = Icons.report_problem;
              consoleIconColor = Colors.red;
            } else if (consoleMessage.messageLevel == ConsoleMessageLevel.TIP) {
              consoleTextColor = Colors.blue;
              consoleIconData = Icons.info;
              consoleIconColor = Colors.blueAccent;
            } else if (consoleMessage.messageLevel ==
                ConsoleMessageLevel.WARNING) {
              consoleBackgroundColor = Color.fromRGBO(255, 251, 227, 1);
              consoleIconData = Icons.report_problem;
              consoleIconColor = Colors.orangeAccent;
            }

            widget.webViewModel
                .addJavaScriptConsoleResults(JavaScriptConsoleResult(
              data: consoleMessage.message,
              textColor: consoleTextColor,
              backgroundColor: consoleBackgroundColor,
              iconData: consoleIconData,
              iconColor: consoleIconColor,
            ));

            if (isCurrentTab(currentWebViewModel)) {
              currentWebViewModel.updateWithValue(widget.webViewModel);
            }
          },
          onLoadResource: (controller, resource) {
            widget.webViewModel.addLoadedResources(resource);

            if (isCurrentTab(currentWebViewModel)) {
              currentWebViewModel.updateWithValue(widget.webViewModel);
            }
          },
          onReceivedServerTrustAuthRequest: (controller, challenge) async {
            if (challenge.iosError != null || challenge.androidError != null) {
              if (Platform.isIOS && challenge.iosError == IOSSslError.UNSPECIFIED) {
                return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
              }
              widget.webViewModel.isSecure = false;
              if (isCurrentTab(currentWebViewModel)) {
                currentWebViewModel.updateWithValue(widget.webViewModel);
              }
              return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.CANCEL);
            }
            return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
          },
          onLoadError: (controller, url, code, message) async {
            controller.loadData(data: """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <style>
    ${await controller.getTRexRunnerCss()}
    </style>
    <style>
    .interstitial-wrapper {
        box-sizing: border-box;
        font-size: 1em;
        line-height: 1.6em;
        margin: 0 auto 0;
        max-width: 600px;
        width: 100%;
    }
    </style>
</head>
<body>
    ${await controller.getTRexRunnerHtml()}
    <div class="interstitial-wrapper">
      <h1>Website not available</h1>
      <p>Could not load web pages at <strong>$url</strong> because:</p>
      <p>$message</p>
    </div>
</body>
            """, baseUrl: url);
          },
    );
  }

  bool isCurrentTab(WebViewModel currentWebViewModel) {
    return currentWebViewModel.tabIndex == widget.webViewModel.tabIndex;
  }
}
