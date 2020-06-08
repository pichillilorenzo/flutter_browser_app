import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_browser/empty_tab.dart';
import 'package:flutter_browser/models/favorite_model.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/popup_menu_actions.dart';
import 'package:flutter_browser/pages/settings_page.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import 'models/webview_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.camera.request();
  await Permission.microphone.request();

  runApp(
    ChangeNotifierProvider(
      create: (context) => BrowserModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Browser',
        theme: ThemeData(
          // is not restarted.
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Browser(),
        });
  }
}

class Browser extends StatefulWidget {
  Browser({Key key}) : super(key: key);

  @override
  _BrowserState createState() => _BrowserState();
}

class _BrowserState extends State<Browser> with ChangeNotifier {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _finOnPageController = TextEditingController();
  FocusNode _focusNode;

  bool _isFindingOnPage = false;

  OutlineInputBorder outlineBorder =  OutlineInputBorder(
    borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    borderRadius: const BorderRadius.all(
      const Radius.circular(50.0),
    ),
  );

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() async {
      if (!_focusNode.hasFocus && _searchController.text.isEmpty) {
        var browserModel = Provider.of<BrowserModel>(context, listen: false);
        var webViewModel = browserModel.getCurrentTab()?.webViewModel;
        var _webViewController = webViewModel?.webViewController;
        _searchController.text = await _webViewController?.getUrl();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          var browserModel = Provider.of<BrowserModel>(context, listen: false);
          var webViewModel = browserModel.getCurrentTab()?.webViewModel;
          var _webViewController = webViewModel?.webViewController;

          if (_webViewController != null) {
            if (await _webViewController.canGoBack()) {
              // get the webview history
              WebHistory webHistory =
                  await _webViewController.getCopyBackForwardList();
              if (webHistory.currentIndex > 1) {
                _webViewController.goBack();
                return false;
              }
            }
          }

          if (webViewModel != null) {
            setState(() {
              browserModel.closeTab(webViewModel.tabIndex);
            });
            FocusScope.of(context).unfocus();
            return false;
          }

          return browserModel.webViewTabs.length == 0;
        },
        child: Scaffold(
            appBar: _buildAppBar(),
            body: _buildWebViewTabs()));
  }

  Consumer<BrowserModel> _buildWebViewTabs() {
    return Consumer<BrowserModel>(
      builder: (context, value, child) {
        var webViewModel = value.getCurrentTab()?.webViewModel;
        if (webViewModel != null && !webViewModel.hasListeners) {
          webViewModel.addListener(() {
            if (!_focusNode.hasFocus &&
                value.getCurrentTabIndex() == webViewModel.tabIndex) {
              _searchController.text = webViewModel.url;
            }
            setState(() {});
          });
        }

        value.addListener(() {
          if (value.webViewTabs.length == 0) {
            _searchController.text = "";
          }
        });

        if (value.webViewTabs.length == 0) {
          return EmptyTab();
        }

        var stackChildrens = <Widget>[
          IndexedStack(
            index: value.getCurrentTabIndex(),
            children: value.webViewTabs,
          ),
        ];

        if (value.getCurrentTab()?.webViewModel?.loaded != true) {
          stackChildrens.add(_createProgressIndicator());
        }

        return Stack(
          children: stackChildrens,
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return _isFindingOnPage ? _buildFindOnPage() : _buildWebViewTabAppBar();
  }

  AppBar _buildWebViewTabAppBar () {
    Widget leading = _buildAppBarHomePageWidget();
    return leading != null ? AppBar(
      leading: _buildAppBarHomePageWidget(),
      titleSpacing: 0.0,
      title: _buildSearchTextField(),
      actions: _buildActionsMenu(),
    ) : AppBar(
      titleSpacing: 10.0,
      title: _buildSearchTextField(),
      actions: _buildActionsMenu(),
    );
  }

  Widget _buildAppBarHomePageWidget() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var _webViewController = webViewModel?.webViewController;

    if (!settings.homePageEnabled) {
      return null;
    }

    return IconButton(
      icon: Icon(Icons.home),
      onPressed: () {
        var url = settings.customUrlHomePage.isNotEmpty ? settings.customUrlHomePage : settings.searchEngine.url;
        if (_webViewController != null) {
          _webViewController.loadUrl(url: url);
        } else {
          addNewTab(url: url);
        }
      },
    );
  }

  AppBar _buildFindOnPage() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var _webViewController = webViewModel?.webViewController;

    return AppBar(
      title: Container(
        height: 40.0,
        child: TextField(
          onSubmitted: (value) {
            _webViewController?.findAllAsync(find: value);
          },
          controller: _finOnPageController,
          textInputAction: TextInputAction.go,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(10.0),
            filled: true,
            fillColor: Colors.white,
            border: outlineBorder,
            focusedBorder: outlineBorder,
            enabledBorder: outlineBorder,
            hintText: "Find on page ...",
            hintStyle: TextStyle(color: Colors.black54, fontSize: 16.0),
          ),
          style: TextStyle(color: Colors.black, fontSize: 16.0),
        )
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.keyboard_arrow_up),
          onPressed: () {
            _webViewController?.findNext(forward: false);
          },
        ),
        IconButton(
          icon: Icon(Icons.keyboard_arrow_down),
          onPressed: () {
            _webViewController?.findNext(forward: true);
          },
        ),
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            _webViewController?.clearMatches();
            _finOnPageController.text = "";

            setState(() {
              _isFindingOnPage = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchTextField() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var _webViewController = webViewModel?.webViewController;
    var isHttps = webViewModel?.url?.startsWith("https://") ?? false;

    return Container(
      height: 40.0,
      child: TextField(
        onSubmitted: (value) {
          var url = value;
          if (!value.startsWith("http")) {
            url = settings.searchEngine.searchUrl + value;
          }
          if (_webViewController != null) {
            _webViewController?.loadUrl(url: value);
          } else {
            addNewTab(url: url);
          }
        },
        keyboardType: TextInputType.url,
        focusNode: _focusNode,
        autofocus: false,
        controller: _searchController,
        textInputAction: TextInputAction.go,
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(10.0),
            filled: true,
            fillColor: Colors.white,
            border: outlineBorder,
            focusedBorder: outlineBorder,
            enabledBorder: outlineBorder,
            hintText: "Search for or type in a web address",
            hintStyle: TextStyle(color: Colors.black54, fontSize: 16.0),
            prefixIcon: Icon(
              isHttps ? Icons.lock : Icons.info_outline,
              color: isHttps ? Colors.green : Colors.grey,
            )
        ),
        style: TextStyle(color: Colors.black, fontSize: 16.0),
      ),
    );
  }

  PreferredSize _createProgressIndicator() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;

    return PreferredSize(
        preferredSize: Size(double.infinity, 4.0),
        child: SizedBox(
            height: 4.0,
            child: LinearProgressIndicator(
              value: webViewModel?.progress ?? 0.0,
            )));
  }

  List<Widget> _buildActionsMenu() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    return <Widget>[
      InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              var browserModel =
                  Provider.of<BrowserModel>(context, listen: true);

              return AlertDialog(
                contentPadding: EdgeInsets.all(0.0),
                content: Container(
                  width: double.maxFinite,
                  child: ListView(
                    children: browserModel.webViewTabs.map((webViewTab) {
                      var uri = Uri.parse(webViewTab.webViewModel.url);
                      var faviconUrl = webViewTab.webViewModel.favicon != null ? webViewTab.webViewModel.favicon.url : uri.origin + "/favicon.ico";

                      return ListTile(
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
                        title: Text(webViewTab.webViewModel.title ??
                            webViewTab.webViewModel.url),
                        subtitle: Text(webViewTab.webViewModel.url,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        onTap: () {
                          setState(() {
                            browserModel
                                .showTab(webViewTab.webViewModel.tabIndex);
                            _searchController.text =
                                webViewTab.webViewModel.url;
                            Navigator.pop(context);
                          });
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.close, size: 20.0),
                              onPressed: () {
                                setState(() {
                                  browserModel.closeTab(
                                      webViewTab.webViewModel.tabIndex);
                                  if (browserModel.webViewTabs.length == 0) {
                                    Navigator.pop(context);
                                  }
                                  FocusScope.of(context).unfocus();
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
        child: Padding(
          padding: settings.homePageEnabled ?
            EdgeInsets.only(left: 20.0, top: 15.0, right: 10.0, bottom: 15.0) :
            EdgeInsets.only(left: 10.0, top: 15.0, right: 10.0, bottom: 15.0),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(width: 2.0, color: Colors.white),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0)),
            child: Padding(
                padding: EdgeInsets.all(5),
                child: Center(
                    child: Text(
                  Provider.of<BrowserModel>(context, listen: false)
                      .webViewTabs
                      .length
                      .toString(),
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ))),
          ),
        ),
      ),
      PopupMenuButton<String>(
        onSelected: _popupMenuChoiceAction,
        itemBuilder: (popupMenuContext) {
          var items = [
            PopupMenuItem<String>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setState) {
                  var browserModel =
                      Provider.of<BrowserModel>(context, listen: true);
                  var webViewModel = browserModel.getCurrentTab()?.webViewModel;
                  var isFavorite = false;
                  FavoriteModel favorite;
                  if (webViewModel != null) {
                    favorite = FavoriteModel(
                        url: webViewModel.url,
                        title: webViewModel.title,
                        favicon: webViewModel.favicon);
                    isFavorite = browserModel.containsFavorite(favorite);
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                          icon: Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            var _webViewController =
                                webViewModel?.webViewController;
                            _webViewController?.goForward();
                            Navigator.pop(popupMenuContext);
                          }),
                      IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              if (webViewModel != null) {
                                if (!browserModel.containsFavorite(favorite)) {
                                  browserModel.addFavorite(favorite);
                                } else if (browserModel
                                    .containsFavorite(favorite)) {
                                  browserModel.removeFavorite(favorite);
                                }
                              }
                            });
                          }),
                      IconButton(
                          icon: Icon(
                            Icons.file_download,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(popupMenuContext);
                          }),
                      IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            var _webViewController =
                                webViewModel?.webViewController;
                            _webViewController?.reload();
                            Navigator.pop(popupMenuContext);
                          }),
                    ],
                  );
                },
              ),
            )
          ];

          var browserModel =
              Provider.of<BrowserModel>(popupMenuContext, listen: false);
          var webViewModel = browserModel.getCurrentTab()?.webViewModel;

          items.addAll(PopupMenuActions.choices.map((choice) {
            switch (choice) {
              case PopupMenuActions.DESKTOP_MODE:
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Checkbox(
                          value: webViewModel?.isDesktopMode ?? false,
                        )
                      ]),
                );
              case PopupMenuActions.SHARE:
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Padding(
                          padding: EdgeInsets.only(right: 12.5),
                          child: Icon(Icons.share, color: Colors.black54,),
                        )
                      ]),
                );
              default:
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
            }
          }).toList());

          return items;
        },
      )
    ];
  }

  void _popupMenuChoiceAction(String choice) async {
    switch (choice) {
      case PopupMenuActions.NEW_TAB:
        addNewTab();
        break;
      case PopupMenuActions.NEW_INCOGNITO_TAB:
        addNewIncognitoTab();
        break;
      case PopupMenuActions.FAVORITES:
        showFavorites();
        break;
      case PopupMenuActions.HISTORY:
        showHistory();
        break;
      case PopupMenuActions.FIND_ON_PAGE:
        showFindOnPage();
        break;
      case PopupMenuActions.SHARE:
        share();
        break;
      case PopupMenuActions.DESKTOP_MODE:
        toggleDesktopMode();
        break;
      case PopupMenuActions.SETTINGS:
        goToSettingsPage();
        break;
    }
  }

  void addNewTab({String url}) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    if (url == null) {
      url = settings.searchEngine.url;
    }

    browserModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel: WebViewModel(url: url),
    ));
  }

  void addNewIncognitoTab() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    browserModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel:
          WebViewModel(url: settings.searchEngine.url, isIncognitoMode: true),
    ));
  }

  void showFavorites() {
    showDialog(
        context: context,
        builder: (context) {
          var browserModel = Provider.of<BrowserModel>(context, listen: true);

          return AlertDialog(
              contentPadding: EdgeInsets.all(0.0),
              content: Container(
                  width: double.maxFinite,
                  child: ListView(
                    children: browserModel.favorites.map((favorite) {
                      var uri = Uri.parse(favorite.url);
                      var faviconUrl = favorite.favicon != null ? favorite.favicon.url : uri.origin + "/favicon.ico";

                      return ListTile(
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
                        title: Text(favorite.title ?? favorite.url),
                        subtitle: Text(favorite.url,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        onTap: () {
                          setState(() {
                            addNewTab(url: favorite.url);
                            Navigator.pop(context);
                          });
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.close, size: 20.0),
                              onPressed: () {
                                setState(() {
                                  browserModel.removeFavorite(favorite);
                                  if (browserModel.favorites.length == 0) {
                                    Navigator.pop(context);
                                  }
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  )));
        });
  }

  void showHistory() {
    showDialog(
        context: context,
        builder: (context) {
          var browserModel = Provider.of<BrowserModel>(context, listen: true);
          var webViewModel = browserModel.getCurrentTab()?.webViewModel;

          return AlertDialog(
              contentPadding: EdgeInsets.all(0.0),
              content: FutureBuilder(
            future: webViewModel?.webViewController?.getCopyBackForwardList(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }

              WebHistory history = snapshot.data;
              return Container(
                  width: double.maxFinite,
                  child: ListView(
                    children: history.list.reversed.map((historyItem) {
                      var uri = Uri.parse(historyItem.url);

                      return ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CachedNetworkImage(
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              imageUrl: uri.origin + "/favicon.ico",
                              height: 30,
                            )
                          ],
                        ),
                        title: Text(historyItem.title ?? historyItem.url),
                        subtitle: Text(historyItem.url,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        onTap: () {
                          webViewModel?.webViewController
                              ?.goTo(historyItem: historyItem);
                          Navigator.pop(context);
                        },
                      );
                    })?.toList(),
                  ));
            },
          ));
        });
  }

  void showFindOnPage() {
    setState(() {
      _isFindingOnPage = true;
    });
  }

  void share() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;

    if (webViewModel != null) {
      Share.share(webViewModel.url, subject: webViewModel.title);
    }
  }

  void toggleDesktopMode() async {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var _webViewController = webViewModel?.webViewController;

    if (_webViewController != null) {
      webViewModel.isDesktopMode = !webViewModel.isDesktopMode;
      await _webViewController.setOptions(
          options: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                  preferredContentMode: webViewModel.isDesktopMode
                      ? UserPreferredContentMode.DESKTOP
                      : UserPreferredContentMode.RECOMMENDED)));
      await _webViewController.reload();
    }
  }

  void goToSettingsPage() {
    Navigator.push(
      context,
        MaterialPageRoute(builder: (context) => SettingsPage())
    );
  }
}
