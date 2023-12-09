import 'dart:async';

// import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/accessiblity/floating_action_button.dart';
import 'package:flutter_browser/custom_image.dart';
import 'package:flutter_browser/tab_viewer.dart';
import 'package:flutter_browser/app_bar/browser_app_bar.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_adeeinappwebview/flutter_adeeinappwebview.dart';
import 'package:provider/provider.dart';

import 'app_bar/tab_viewer_app_bar.dart';
import 'empty_tab.dart';
import 'models/browser_model.dart';
import 'pages/settings/main.dart';

class Browser extends StatefulWidget {
  const Browser({Key? key}) : super(key: key);

  @override
  State<Browser> createState() => _BrowserState();
}

class _BrowserState extends State<Browser> with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('co.zew.deebrowser.intent_data');

  var _isRestored = false;

  @override
  void initState() {
    super.initState();
    getIntentData();
  }

  getIntentData() async {
    if (Util.isAndroid()) {
      String? url = await platform.invokeMethod("getIntentData");
      if (url != null) {
        if (kDebugMode) {
          print("*********** Url in getIntendData is: $url");
        }

        if (mounted) {
          var browserModel = Provider.of<BrowserModel>(context, listen: false);
          browserModel.addTab(WebViewTab(
            key: GlobalKey(),
            webViewModel: WebViewModel(
                url: WebUri(url),
                settings: browserModel.getDefaultTabSettings()),
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  restore() async {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    browserModel.restore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isRestored) {
      _isRestored = true;
      restore();
    }
    precacheImage(const AssetImage("assets/icon/icon.png"), context);
  }

  @override
  Widget build(BuildContext context) {
    return _buildBrowser();
  }

  Widget _buildBrowser() {
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    browserModel.addListener(() {
      browserModel.save();
    });
    currentWebViewModel.addListener(() {
      browserModel.save();
    });

    var canShowTabScroller =
        browserModel.showTabScroller && browserModel.webViewTabs.isNotEmpty;

    return IndexedStack(
      index: canShowTabScroller ? 1 : 0,
      children: [
        _buildWebViewTabs(),
        canShowTabScroller ? _buildWebViewTabsViewer() : Container()
      ],
    );
  }

  Widget _buildWebViewTabs() {
    return WillPopScope(
        onWillPop: () async {
          var browserModel = Provider.of<BrowserModel>(context, listen: false);
          var webViewModel = browserModel.getCurrentTab()?.webViewModel;
          var webViewController = webViewModel?.webViewController;

          if (webViewController != null) {
            if (await webViewController.canGoBack()) {
              webViewController.goBack();
              return false;
            }
          }

          if (webViewModel != null && webViewModel.tabIndex != null) {
            setState(() {
              browserModel.closeTab(webViewModel.tabIndex!);
            });
            if (mounted) {
              FocusScope.of(context).unfocus();
            }
            return false;
          }

          return browserModel.webViewTabs.isEmpty;
        },
        child: Listener(
          onPointerUp: (_) {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              currentFocus.focusedChild!.unfocus();
            }
          },
          child: Scaffold(
            appBar: const BrowserAppBar(),
            body: _buildWebViewTabsContent(),
            floatingActionButton: MovableAccessibilityFAB(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()));
              },
            ),
          ),
        ));
  }

  Widget _buildWebViewTabsContent() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    if (browserModel.webViewTabs.isEmpty) {
      return const EmptyTab();
    }

    for (final webViewTab in browserModel.webViewTabs) {
      var isCurrentTab = webViewTab.webViewModel.tabIndex ==
          browserModel.getCurrentTabIndex();

      if (isCurrentTab) {
        Future.delayed(const Duration(milliseconds: 100), () {
          webViewTabStateKey.currentState?.onShowTab();
        });
      } else {
        webViewTabStateKey.currentState?.onHideTab();
      }
    }

    var stackChildren = <Widget>[
      browserModel.getCurrentTab() ?? Container(),
      _createProgressIndicator()
    ];

    return Stack(
      children: stackChildren,
    );
  }

  Widget _createProgressIndicator() {
    return Selector<WebViewModel, double>(
        selector: (context, webViewModel) => webViewModel.progress,
        builder: (context, progress, child) {
          if (progress >= 1.0) {
            return Container();
          }
          return PreferredSize(
              preferredSize: const Size(double.infinity, 4.0),
              child: SizedBox(
                  height: 4.0,
                  child: LinearProgressIndicator(
                    value: progress,
                  )));
        });
  }

  Widget _buildWebViewTabsViewer() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    // ignore: sized_box_for_whitespace
    return Container(
      width: double.infinity,
      child: Drawer(
        child: Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  browserModel.showTabScroller = false;
                  browserModel.showTab(browserModel.getCurrentTabIndex());
                },
              ),
              title:
                  Text('Tabs [${browserModel.webViewTabs.length.toString()}]'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    browserModel.addTab(WebViewTab(
                      key: GlobalKey(),
                      webViewModel: WebViewModel(
                          url: WebUri(''),
                          settings: browserModel.getDefaultTabSettings()),
                    ));
                  },
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: browserModel.webViewTabs.map((webViewTab) {
                    var isCurrentTab = browserModel.getCurrentTabIndex() ==
                        webViewTab.webViewModel.tabIndex;

                    // Change here: Check if the tab is in incognito mode
                    var leadingWidget = webViewTab.webViewModel.isIncognitoMode
                        ? const Icon(MaterialCommunityIcons.incognito,
                            color: Colors.black) // Incognito icon
                        : (webViewTab.webViewModel.favicon != null
                            ? CustomImage(
                                url: webViewTab.webViewModel.favicon!.url,
                                maxWidth: 30.0,
                                height: 30.0,
                              )
                            : const Icon(Icons.web,
                                color: Colors
                                    .black)); // Default icon if no favicon

                    return ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[leadingWidget],
                      ),
                      title: Text(
                        webViewTab.webViewModel.isIncognitoMode
                            ? (webViewTab.webViewModel.title ??
                                webViewTab.webViewModel.url?.toString() ??
                                "")
                            : webViewTab.webViewModel.title ??
                                webViewTab.webViewModel.url?.toString() ??
                                "",
                        maxLines: 2,
                        style: TextStyle(
                          color:
                              isCurrentTab ? Colors.deepPurple : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        webViewTab.webViewModel.url?.toString() ?? "",
                        style: TextStyle(
                          color:
                              isCurrentTab ? Colors.deepPurple : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20.0,
                              color: isCurrentTab
                                  ? Colors.deepPurple
                                  : Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                if (webViewTab.webViewModel.tabIndex != null) {
                                  browserModel.closeTab(
                                      webViewTab.webViewModel.tabIndex!);
                                  if (browserModel.webViewTabs.isEmpty) {
                                    browserModel.showTabScroller = false;
                                  }
                                }
                              });
                            },
                          )
                        ],
                      ),
                      onTap: () {
                        // Check if tabIndex is not null before using it
                        if (webViewTab.webViewModel.tabIndex != null) {
                          browserModel.showTabScroller = false;
                          browserModel.showTab(webViewTab.webViewModel
                              .tabIndex!); // Use the non-null assertion operator (!) after checking for null
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewTabsViewer_old() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    return WillPopScope(
        onWillPop: () async {
          browserModel.showTabScroller = false;
          return false;
        },
        child: Scaffold(
            appBar: const TabViewerAppBar(),
            body: TabViewer(
              currentIndex: browserModel.getCurrentTabIndex(),
              children: browserModel.webViewTabs.map((webViewTab) {
                webViewTabStateKey.currentState?.pause();
                var screenshotData = webViewTab.webViewModel.screenshot;
                Widget screenshotImage = Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  width: double.infinity,
                  child: screenshotData != null
                      ? Image.memory(screenshotData)
                      : null,
                );

                var url = webViewTab.webViewModel.url;
                var faviconUrl = webViewTab.webViewModel.favicon != null
                    ? webViewTab.webViewModel.favicon!.url
                    : (url != null && ["http", "https"].contains(url.scheme)
                        ? Uri.parse("${url.origin}/favicon.ico")
                        : null);

                var isCurrentTab = browserModel.getCurrentTabIndex() ==
                    webViewTab.webViewModel.tabIndex;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Material(
                      color: isCurrentTab
                          ? Colors.deepPurple
                          : (webViewTab.webViewModel.isIncognitoMode
                              ? Colors.black
                              : Colors.white),
                      child: ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // CachedNetworkImage(
                            //   placeholder: (context, url) =>
                            //   url == "about:blank"
                            //       ? Container()
                            //       : CircularProgressIndicator(),
                            //   imageUrl: faviconUrl,
                            //   height: 30,
                            // )
                            CustomImage(
                                url: faviconUrl, maxWidth: 30.0, height: 30.0)
                          ],
                        ),
                        title: Text(
                            webViewTab.webViewModel.title ??
                                webViewTab.webViewModel.url?.toString() ??
                                "",
                            maxLines: 2,
                            style: TextStyle(
                              color: webViewTab.webViewModel.isIncognitoMode ||
                                      isCurrentTab
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis),
                        subtitle:
                            Text(webViewTab.webViewModel.url?.toString() ?? "",
                                style: TextStyle(
                                  color:
                                      webViewTab.webViewModel.isIncognitoMode ||
                                              isCurrentTab
                                          ? Colors.white60
                                          : Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 20.0,
                                color:
                                    webViewTab.webViewModel.isIncognitoMode ||
                                            isCurrentTab
                                        ? Colors.white60
                                        : Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (webViewTab.webViewModel.tabIndex !=
                                      null) {
                                    browserModel.closeTab(
                                        webViewTab.webViewModel.tabIndex!);
                                    if (browserModel.webViewTabs.isEmpty) {
                                      browserModel.showTabScroller = false;
                                    }
                                  }
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: screenshotImage,
                    )
                  ],
                );
              }).toList(),
              onTap: (index) async {
                browserModel.showTabScroller = false;
                browserModel.showTab(index);
              },
            )));
  }
}
