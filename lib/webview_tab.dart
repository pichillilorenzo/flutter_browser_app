import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_browser/main.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'javascript_console_result.dart';
import 'long_press_alert_dialog.dart';
import 'models/browser_model.dart';

class WebViewTab extends StatefulWidget {
  final GlobalKey<WebViewTabState> key;

  WebViewTab({required this.key, required this.webViewModel}) : super(key: key);

  final WebViewModel webViewModel;

  @override
  WebViewTabState createState() => WebViewTabState();
}

class WebViewTabState extends State<WebViewTab> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  bool _isWindowClosed = false;

  TextEditingController _httpAuthUsernameController = TextEditingController();
  TextEditingController _httpAuthPasswordController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _webViewController = null;
    widget.webViewModel.webViewController = null;

    _httpAuthUsernameController.dispose();
    _httpAuthPasswordController.dispose();

    WidgetsBinding.instance!.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_webViewController != null && Platform.isAndroid) {
      if (state == AppLifecycleState.paused) {
        pauseAll();
      } else {
        resumeAll();
      }
    }
  }

  void pauseAll() {
    if (Platform.isAndroid) {
      _webViewController?.android.pause();
    }
    pauseTimers();
  }

  void resumeAll() {
    if (Platform.isAndroid) {
      _webViewController?.android.resume();
    }
    resumeTimers();
  }

  void pause() {
    if (Platform.isAndroid) {
      _webViewController?.android.pause();
    }
  }

  void resume() {
    if (Platform.isAndroid) {
      _webViewController?.android.resume();
    }
  }

  void pauseTimers() {
    _webViewController?.pauseTimers();
  }

  void resumeTimers() {
    _webViewController?.resumeTimers();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _buildWebView(),
    );
  }

  InAppWebView _buildWebView() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);

    if (Platform.isAndroid) {
      AndroidInAppWebViewController.setWebContentsDebuggingEnabled(settings.debuggingEnabled);
    }

    var initialOptions = widget.webViewModel.options!;
    initialOptions.crossPlatform.useOnDownloadStart = true;
    initialOptions.crossPlatform.useOnLoadResource = true;
    initialOptions.crossPlatform.useShouldOverrideUrlLoading = true;
    initialOptions.crossPlatform.javaScriptCanOpenWindowsAutomatically = true;
    initialOptions.crossPlatform.userAgent = "Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36";
    initialOptions.crossPlatform.transparentBackground = true;

    initialOptions.android.safeBrowsingEnabled = true;
    initialOptions.android.disableDefaultErrorPage = true;
    initialOptions.android.supportMultipleWindows = true;
    initialOptions.android.useHybridComposition = true;
    initialOptions.android.verticalScrollbarThumbColor = Color.fromRGBO(0, 0, 0, 0.5);
    initialOptions.android.horizontalScrollbarThumbColor = Color.fromRGBO(0, 0, 0, 0.5);

    initialOptions.ios.allowsLinkPreview = false;
    initialOptions.ios.isFraudulentWebsiteWarningEnabled = true;
    initialOptions.ios.disableLongPressContextMenuOnLinks = true;
    initialOptions.ios.allowingReadAccessTo = Uri.parse('file://$WEB_ARCHIVE_DIR/');

    return InAppWebView(
        initialUrlRequest: URLRequest(
          url: widget.webViewModel.url
        ),
        initialOptions: initialOptions,
        windowId: widget.webViewModel.windowId,
        onWebViewCreated: (controller) async {
          initialOptions.crossPlatform.transparentBackground = false;
          await controller.setOptions(options: initialOptions);
          
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
          widget.webViewModel.isSecure = Util.urlIsSecure(url!);
          widget.webViewModel.url = url;
          widget.webViewModel.loaded = false;
          widget.webViewModel.setLoadedResources([]);
          widget.webViewModel.setJavaScriptConsoleResults([]);

          if (isCurrentTab(currentWebViewModel)) {
            currentWebViewModel.updateWithValue(widget.webViewModel);
          } else if (widget.webViewModel.needsToCompleteInitialLoad) {
            controller.stopLoading();
          }
        },
        onLoadStop: (controller, url) async {
          widget.webViewModel.url = url;
          widget.webViewModel.favicon = null;
          widget.webViewModel.loaded = true;

          var sslCertificateFuture = _webViewController?.getCertificate();
          var titleFuture = _webViewController?.getTitle();
          var faviconsFuture = _webViewController?.getFavicons();

          var sslCertificate = await sslCertificateFuture;
          if (sslCertificate == null && !Util.isLocalizedContent(url!)) {
            widget.webViewModel.isSecure = false;
          }

          widget.webViewModel.title = await titleFuture;

          List<Favicon>? favicons = await faviconsFuture;
          if (favicons != null && favicons.isNotEmpty) {
            for (var fav in favicons) {
              if (widget.webViewModel.favicon == null) {
                widget.webViewModel.favicon = fav;
              } else {
                if ((widget.webViewModel.favicon!.width == null &&
                    !widget.webViewModel.favicon!.url.toString()
                        .endsWith("favicon.ico")) ||
                    (fav.width != null &&
                        widget.webViewModel.favicon!.width != null &&
                        fav.width! > widget.webViewModel.favicon!.width!)) {
                  widget.webViewModel.favicon = fav;
                }
              }
            }
          }

          if (isCurrentTab(currentWebViewModel)) {
            widget.webViewModel.needsToCompleteInitialLoad = false;
            currentWebViewModel.updateWithValue(widget.webViewModel);

            var screenshotData = _webViewController?.takeScreenshot(screenshotConfiguration: ScreenshotConfiguration(
                compressFormat: CompressFormat.JPEG,
                quality: 20
            )).timeout(Duration(milliseconds: 1500), onTimeout: () => null,);
            widget.webViewModel.screenshot = await screenshotData;
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

            var requestFocusNodeHrefResult = await _webViewController?.requestFocusNodeHref();

            if (requestFocusNodeHrefResult != null) {
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
          }
        },
        onConsoleMessage: (controller, consoleMessage) {
          Color consoleTextColor = Colors.black;
          Color consoleBackgroundColor = Colors.transparent;
          IconData? consoleIconData;
          Color? consoleIconColor;
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
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          var url = navigationAction.request.url;

          if (url != null && !["http", "https", "file",
            "chrome", "data", "javascript",
            "about"].contains(url.scheme)) {
            if (await canLaunch(url.toString())) {
              // Launch the App
              await launch(
                url.toString(),
              );
              // and cancel the request
              return NavigationActionPolicy.CANCEL;
            }
          }

          return NavigationActionPolicy.ALLOW;
        },
        onDownloadStart: (controller, url) async {
          String path = url.path;
          String fileName = path.substring(path.lastIndexOf('/') + 1);

          final taskId = await FlutterDownloader.enqueue(
            url: url.toString(),
            fileName: fileName,
            savedDir: (await getTemporaryDirectory()).path,
            showNotification: true,
            openFileFromNotification: true,
          );
        },
        onReceivedServerTrustAuthRequest: (controller, challenge) async {
          var sslError = challenge.protectionSpace.sslError;
          if (sslError != null && (sslError.iosError != null || sslError.androidError != null)) {
            if (Platform.isIOS && sslError.iosError == IOSSslError.UNSPECIFIED) {
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
          if (Platform.isIOS && code == -999) {
            // NSURLErrorDomain
            return;
          }

          var errorUrl = url ?? widget.webViewModel.url ?? Uri.parse('about:blank');

          _webViewController?.loadData(data: """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <style>
    ${await _webViewController?.getTRexRunnerCss()}
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
    ${await _webViewController?.getTRexRunnerHtml()}
    <div class="interstitial-wrapper">
      <h1>Website not available</h1>
      <p>Could not load web pages at <strong>$errorUrl</strong> because:</p>
      <p>$message</p>
    </div>
</body>
    """, baseUrl: errorUrl, androidHistoryUrl: errorUrl);

          widget.webViewModel.url = url;
          widget.webViewModel.isSecure = false;

          if (isCurrentTab(currentWebViewModel)) {
            currentWebViewModel.updateWithValue(widget.webViewModel);
          }
        },
        onTitleChanged: (controller, title) async {
          widget.webViewModel.title = title;

          if (isCurrentTab(currentWebViewModel)) {
            currentWebViewModel.updateWithValue(widget.webViewModel);
          }
        },
        onCreateWindow: (controller, createWindowRequest) async {
          var webViewTab = WebViewTab(
            key: GlobalKey(),
            webViewModel: WebViewModel(
              url: Uri.parse("about:blank"),
              windowId: createWindowRequest.windowId
            ),
          );

          browserModel.addTab(
              webViewTab
          );

          return true;
        },
        onCloseWindow: (controller) {
          if (_isWindowClosed) {
            return;
          }
          _isWindowClosed = true;
          if (widget.webViewModel.tabIndex != null) {
            browserModel.closeTab(widget.webViewModel.tabIndex!);
          }
        },
        androidOnPermissionRequest: (InAppWebViewController controller, String origin, List<String> resources) async {
          return PermissionRequestResponse(resources: resources, action: PermissionRequestResponseAction.GRANT);
        },
        onReceivedHttpAuthRequest: (InAppWebViewController controller, URLAuthenticationChallenge challenge) async {
          var action = await createHttpAuthDialog(challenge);
          return HttpAuthResponse(
              username: _httpAuthUsernameController.text.trim(),
              password: _httpAuthPasswordController.text,
              action: action,
              permanentPersistence: true);
        },
    );
  }

  bool isCurrentTab(WebViewModel currentWebViewModel) {
    return currentWebViewModel.tabIndex == widget.webViewModel.tabIndex;
  }

  Future<HttpAuthResponseAction> createHttpAuthDialog(URLAuthenticationChallenge challenge) async {
    HttpAuthResponseAction action = HttpAuthResponseAction.CANCEL;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Login"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(challenge.protectionSpace.host),
              TextField(
                decoration: InputDecoration(
                  labelText: "Username"
                ),
                controller: _httpAuthUsernameController,
              ),
              TextField(
                decoration: InputDecoration(
                    labelText: "Password"
                ),
                controller: _httpAuthPasswordController,
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Cancel"),
              onPressed: () {
                action = HttpAuthResponseAction.CANCEL;
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("Ok"),
              onPressed: () {
                action = HttpAuthResponseAction.PROCEED;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    return action;
  }

  void onShowTab() async {
    this.resume();
    if (widget.webViewModel.needsToCompleteInitialLoad) {
      widget.webViewModel.needsToCompleteInitialLoad = false;
      await widget.webViewModel.webViewController?.loadUrl(urlRequest: URLRequest(url: widget.webViewModel.url));

    }
  }

  void onHideTab() async {
    this.pause();
  }
}
