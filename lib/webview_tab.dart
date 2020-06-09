import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

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

  @override void dispose() {
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: InAppWebView(
            initialUrl: widget.webViewModel.url,
            initialOptions: InAppWebViewGroupOptions(
                crossPlatform:
                    InAppWebViewOptions(
                      debuggingEnabled: settings.debuggingEnabled,
                      incognito: widget.webViewModel.isIncognitoMode,
                      useOnDownloadStart: true,
                      useOnLoadResource: true
                    )),
            onWebViewCreated: (controller) async {
              _webViewController = controller;
              widget.webViewModel.webViewController = controller;

              widget.webViewModel.options = await controller.getOptions();

              browserModel.notify();
            },
            onLoadStart: (controller, url) async {
              widget.webViewModel.url = url;
              widget.webViewModel.loaded = false;
              widget.webViewModel.loadedResources.clear();
              widget.webViewModel.javaScriptConsoleResults.clear();

              browserModel.notify();
            },
            onLoadStop: (controller, url) async {
              widget.webViewModel.url = url;
              widget.webViewModel.title = await _webViewController?.getTitle();
              widget.webViewModel.favicon = null;
              widget.webViewModel.loaded = true;

              List<Favicon> favicons = await _webViewController?.getFavicons();
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
                            fav.width >
                                widget.webViewModel.favicon.width)) {
                      widget.webViewModel.favicon = fav;
                    }
                  }
                }
              }

              browserModel.notify();
            },
            onProgressChanged: (controller, progress) {
              widget.webViewModel.progress = progress / 100;
              browserModel.notify();
            },
            onUpdateVisitedHistory:
                (controller, url, androidIsReload) async {
              widget.webViewModel.url = url;
              widget.webViewModel.title = await _webViewController?.getTitle();
              browserModel.notify();
            },
            onLongPressHitTestResult: (controller, hitTestResult) {
              if (LongPressAlertDialog.HIT_TEST_RESULT_SUPPORTED.contains(hitTestResult.type)) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return LongPressAlertDialog(webViewModel: widget.webViewModel, hitTestResult: hitTestResult,);
                  },
                );
              }
            },
            onConsoleMessage: (controller, consoleMessage) {
              widget.webViewModel.javaScriptConsoleResults.add(
                RichText(
                  text: TextSpan(
                    text: consoleMessage.message,
                    style: TextStyle(
                      color: consoleMessage.messageLevel == ConsoleMessageLevel.ERROR ? Colors.red : Colors.black
                    )
                  ),
                )
              );
              browserModel.notify();
            },
            onLoadResource: (controller, resource) {
              widget.webViewModel.loadedResources.add(resource);
              browserModel.notify();
            },
          ),
        )
      ],
    );
  }
}

