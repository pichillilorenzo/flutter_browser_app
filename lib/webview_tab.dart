import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import 'models/browser_model.dart';

class WebViewTab extends StatefulWidget {
  WebViewTab({Key key, this.webViewModel}) : super(key: key);

  final WebViewModel webViewModel;

  @override
  _WebViewTabState createState() => _WebViewTabState();
}

class _WebViewTabState extends State<WebViewTab> {
  InAppWebViewController _webViewController;

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
                    )),
            onWebViewCreated: (controller) async {
              _webViewController = controller;
              widget.webViewModel.webViewController = controller;

              widget.webViewModel.options = await controller.getOptions();
            },
            onLoadStart: (controller, url) async {
              widget.webViewModel.url = url;
              widget.webViewModel.loaded = false;
            },
            onLoadStop: (controller, url) async {
              widget.webViewModel.url = url;
              widget.webViewModel.title = await controller.getTitle();
              widget.webViewModel.favicon = null;
              widget.webViewModel.loaded = true;

              List<Favicon> favicons = await controller.getFavicons();
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
            },
            onProgressChanged: (controller, progress) {
              widget.webViewModel.progress = progress / 100;
            },
            onUpdateVisitedHistory:
                (controller, url, androidIsReload) async {
              widget.webViewModel.url = url;
              widget.webViewModel.title = await controller.getTitle();
            },
            onLongPressHitTestResult: (controller, hitTestResult) {
              var browserModel = Provider.of<BrowserModel>(context, listen: false);
              var settings = browserModel.getSettings();
              
              var uri = Uri.parse(hitTestResult.extra);
              var faviconUrl = uri.origin + "/favicon.ico";

              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.all(0.0),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  CachedNetworkImage(
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(),
                                    imageUrl: faviconUrl,
                                    height: 30,
                                  )
                                ],
                              ),
                              title: const Text("Link"),
                              subtitle: Text(hitTestResult.extra, maxLines: 2, overflow: TextOverflow.ellipsis,),
                              isThreeLine: true,
                            ),
                            ListTile(
                              title: Center(child: const Text("Preview")),
                              subtitle: Container(
                                height: 250,
                                child: InAppWebView(
                                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                                    new Factory<OneSequenceGestureRecognizer>(
                                          () => new EagerGestureRecognizer(),
                                    ),
                                  ].toSet(),
                                  initialUrl: hitTestResult.extra,
                                  initialOptions: InAppWebViewGroupOptions(
                                      crossPlatform:
                                      InAppWebViewOptions(
                                        debuggingEnabled: settings.debuggingEnabled,
                                      )),
                                ),
                              ),
                            ),
                            ListTile(
                              title: const Text("Open in a new tab"),
                              onTap: () {
                                browserModel.addTab(WebViewTab(
                                  key: GlobalKey(),
                                  webViewModel: WebViewModel(
                                      url: hitTestResult.extra
                                  ),
                                ));
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text("Open in a new incognito tab"),
                              onTap: () {
                                browserModel.addTab(WebViewTab(
                                  key: GlobalKey(),
                                  webViewModel: WebViewModel(
                                      url: hitTestResult.extra,
                                      isIncognitoMode: true
                                  ),
                                ));
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text("Copy address link"),
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: hitTestResult.extra));
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text("Share link"),
                              onTap: () {
                                Share.share(hitTestResult.extra);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
              );
            },
          ),
        )
      ],
    );
  }
}
