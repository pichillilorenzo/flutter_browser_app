import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_browser/app_bar/show_url_info_popup.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/favorite_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/pages/developers_page.dart';
import 'package:flutter_browser/pages/settings_page.dart';
import 'package:flutter_browser/tab_popup_menu_actions.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import '../custom_popup_dialog.dart';
import '../custom_popup_menu_item.dart';
import '../popup_menu_actions.dart';
import '../webview_tab.dart';

class WebViewTabAppBar extends StatefulWidget {
  final void Function() showFindOnPage;

  WebViewTabAppBar({Key key, this.showFindOnPage}) : super(key: key);

  @override
  _WebViewTabAppBarState createState() => _WebViewTabAppBarState();
}

class _WebViewTabAppBarState extends State<WebViewTabAppBar> {
  TextEditingController _searchController = TextEditingController();
  FocusNode _focusNode;

  GlobalKey tabInkWellKey = new GlobalKey();

  Duration customPopupDialogTransitionDuration = const Duration(milliseconds: 300);
  CustomPopupDialogPageRoute route;

  OutlineInputBorder outlineBorder = OutlineInputBorder(
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
        var browserModel = Provider.of<BrowserModel>(context, listen: true);
        var webViewModel = browserModel.getCurrentTab()?.webViewModel;
        var _webViewController = webViewModel?.webViewController;
        _searchController?.text = await _webViewController?.getUrl();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusNode = null;
    _searchController.dispose();
    _searchController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<WebViewModel, String>(
        selector: (context, webViewModel) => webViewModel.url,
        builder: (context, url, child) {
          if (url == null) {
            _searchController?.text = "";
          }
          if (_focusNode != null && !_focusNode.hasFocus) {
            _searchController?.text = url;
          }

          Widget leading = _buildAppBarHomePageWidget();

          return Selector<WebViewModel, bool>(
              selector: (context, webViewModel) => webViewModel.isIncognitoMode,
              builder: (context, isIncognitoMode, child) {
                return leading != null
                    ? AppBar(
                        backgroundColor:
                            isIncognitoMode ? Colors.black87 : Colors.blue,
                        leading: _buildAppBarHomePageWidget(),
                        titleSpacing: 0.0,
                        title: _buildSearchTextField(),
                        actions: _buildActionsMenu(),
                      )
                    : AppBar(
                        backgroundColor:
                            isIncognitoMode ? Colors.black87 : Colors.blue,
                        titleSpacing: 10.0,
                        title: _buildSearchTextField(),
                        actions: _buildActionsMenu(),
                      );
              });
        });
  }

  Widget _buildAppBarHomePageWidget() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    var webViewModel = Provider.of<WebViewModel>(context, listen: true);
    var _webViewController = webViewModel?.webViewController;

    if (!settings.homePageEnabled) {
      return null;
    }

    return IconButton(
      icon: Icon(Icons.home),
      onPressed: () {
        var url = settings.customUrlHomePage.isNotEmpty
            ? settings.customUrlHomePage
            : settings.searchEngine.url;
        if (_webViewController != null) {
          _webViewController.loadUrl(url: url);
        } else {
          addNewTab(url: url);
        }
      },
    );
  }

  Widget _buildSearchTextField() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    var webViewModel = Provider.of<WebViewModel>(context, listen: true);
    var _webViewController = webViewModel?.webViewController;

    return Container(
      height: 40.0,
      child: Stack(
        children: <Widget>[
          TextField(
            onSubmitted: (value) {
              var url = value;
              if (!value.startsWith("http") && !value.startsWith("file://") && value.trim() != "about:blank") {
                url = settings.searchEngine.searchUrl + value;
              }

              if (_webViewController != null) {
                _webViewController?.loadUrl(url: url);
              } else {
                addNewTab(url: url);
                webViewModel.url = url;
              }
            },
            keyboardType: TextInputType.url,
            focusNode: _focusNode,
            autofocus: false,
            controller: _searchController,
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(
                  left: 45.0, top: 10.0, right: 10.0, bottom: 10.0),
              filled: true,
              fillColor: Colors.white,
              border: outlineBorder,
              focusedBorder: outlineBorder,
              enabledBorder: outlineBorder,
              hintText: "Search for or type in a web address",
              hintStyle: TextStyle(color: Colors.black54, fontSize: 16.0),
            ),
            style: TextStyle(color: Colors.black, fontSize: 16.0),
          ),
          IconButton(
            icon: Selector<WebViewModel, bool>(
              selector: (context, webViewModel) => webViewModel.isSecure,
              builder: (context, isSecure, child) {
                return Icon(
                  isSecure ? Icons.lock : Icons.info_outline,
                  color: isSecure ? Colors.green : Colors.grey,
                );
              },
            ),
            onPressed: () {
              showUrlInfo();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionsMenu() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    return <Widget>[
      InkWell(
        key: tabInkWellKey,
        onLongPress: () {
          final RenderBox box = tabInkWellKey.currentContext.findRenderObject();
          Offset position = box.localToGlobal(Offset.zero);

          showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(position.dx,
                      position.dy + box.size.height, box.size.width, 0),
                  items: TabPopupMenuActions.choices.map((tabPopupMenuAction) {
                    IconData iconData;
                    switch (tabPopupMenuAction) {
                      case TabPopupMenuActions.CLOSE_TABS:
                        iconData = Icons.cancel;
                        break;
                      case TabPopupMenuActions.NEW_TAB:
                        iconData = Icons.add;
                        break;
                      case TabPopupMenuActions.NEW_INCOGNITO_TAB:
                        iconData = Icons.computer;
                        break;
                    }

                    return PopupMenuItem<String>(
                      value: tabPopupMenuAction,
                      child: Row(children: [
                        Icon(
                          iconData,
                          color: Colors.black54,
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10.0),
                          child: Text(tabPopupMenuAction),
                        )
                      ]),
                    );
                  }).toList())
              .then((value) {
            switch (value) {
              case TabPopupMenuActions.CLOSE_TABS:
                browserModel.closeAllTabs();
                break;
              case TabPopupMenuActions.NEW_TAB:
                addNewTab();
                break;
              case TabPopupMenuActions.NEW_INCOGNITO_TAB:
                addNewIncognitoTab();
                break;
            }
          });
        },
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
                      var faviconUrl = webViewTab.webViewModel.favicon != null
                          ? webViewTab.webViewModel.favicon.url
                          : (["http", "https"].contains(uri.scheme) ? uri.origin + "/favicon.ico" : "");

                      return Material(
                        color: webViewTab.webViewModel.isIncognitoMode
                            ? Colors.black87
                            : Colors.transparent,
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              CachedNetworkImage(
                                placeholder: (context, url) =>
                                    url == "about:blank" ? Container() : CircularProgressIndicator(),
                                imageUrl: faviconUrl,
                                height: 30,
                              )
                            ],
                          ),
                          title: Text(
                              webViewTab.webViewModel.title ??
                                  webViewTab.webViewModel.url,
                              maxLines: 2,
                              style: TextStyle(
                                color: webViewTab.webViewModel.isIncognitoMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(webViewTab.webViewModel.url,
                              style: TextStyle(
                                color: webViewTab.webViewModel.isIncognitoMode
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
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
                                icon: Icon(
                                  Icons.close,
                                  size: 20.0,
                                  color: webViewTab.webViewModel.isIncognitoMode
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    browserModel.closeTab(
                                        webViewTab.webViewModel.tabIndex);
                                    if (browserModel.webViewTabs.length == 0) {
                                      Navigator.pop(context);
                                    }
                                    _searchController.text = browserModel
                                            .getCurrentTab()
                                            ?.webViewModel
                                            ?.url ??
                                        "";
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            ],
                          ),
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
          padding: settings.homePageEnabled
              ? EdgeInsets.only(
                  left: 20.0, top: 15.0, right: 10.0, bottom: 15.0)
              : EdgeInsets.only(
                  left: 10.0, top: 15.0, right: 10.0, bottom: 15.0),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(width: 2.0, color: Colors.white),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0)),
            constraints: BoxConstraints(minWidth: 25.0),
            child: Container(
                child: Center(
                    child: Text(
              Provider.of<BrowserModel>(context, listen: true)
                  .webViewTabs
                  .length
                  .toString(),
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0),
            ))),
          ),
        ),
      ),
      PopupMenuButton<String>(
        onSelected: _popupMenuChoiceAction,
        itemBuilder: (popupMenuContext) {
          var items = [
            CustomPopupMenuItem<String>(
              enabled: true,
              isIconButtonRow: true,
              child: StatefulBuilder(
                builder: (statefulContext, setState) {
                  var browserModel =
                      Provider.of<BrowserModel>(statefulContext, listen: true);
                  var webViewModel = Provider.of<WebViewModel>(statefulContext, listen: true);
                  var _webViewController = webViewModel?.webViewController;

                  var isFavorite = false;
                  FavoriteModel favorite;

                  if (webViewModel != null) {
                    favorite = FavoriteModel(
                        url: webViewModel.url,
                        title: webViewModel.title,
                        favicon: webViewModel.favicon);
                    isFavorite = browserModel.containsFavorite(favorite);
                  }

                  var children = <Widget>[];

                  if (Platform.isIOS) {
                    children.add(
                      Container(
                          width: 30.0,
                          child: IconButton(
                              padding: const EdgeInsets.all(0.0),
                              icon: Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                _webViewController?.goBack();
                                Navigator.pop(popupMenuContext);
                              })),
                    );
                  }

                  children.addAll([
                    Container(
                        width: 30.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              _webViewController?.goForward();
                              Navigator.pop(popupMenuContext);
                            })),
                    Container(
                        width: 30.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                if (webViewModel != null) {
                                  if (!browserModel
                                      .containsFavorite(favorite)) {
                                    browserModel.addFavorite(favorite);
                                  } else if (browserModel
                                      .containsFavorite(favorite)) {
                                    browserModel.removeFavorite(favorite);
                                  }
                                }
                              });
                            })),
                    Container(
                        width: 30.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.file_download,
                              color: Colors.black,
                            ),
                            onPressed: () async {
                              Navigator.pop(popupMenuContext);
                              if (webViewModel.url.startsWith("http")) {
                                if (Platform.isAndroid) {
                                  var uri = Uri.parse(webViewModel.url);

                                  var webArchiveDirectoryPath = (await getApplicationSupportDirectory()).path;
                                  var webArchivePath = (await _webViewController?.android?.saveWebArchive(
                                      basename: webArchiveDirectoryPath + Platform.pathSeparator + uri.host + uri.path.replaceAll("/", "-") + uri.query + ".mht",
                                      autoname: false)
                                  );
                                  if (webArchivePath != null) {
                                    browserModel.addWebArchive(webViewModel.url, webArchivePath);
                                    Scaffold.of(context).showSnackBar(SnackBar(
                                      content: Text("Saved to " + webArchivePath),
                                    ));
                                  } else {
                                    Scaffold.of(context).showSnackBar(SnackBar(
                                      content: Text("Unable to save!"),
                                    ));
                                  }
                                } else {
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text("Unsupported for this platform!"),
                                  ));
                                }
                              }
                            })),
                    Container(
                        width: 30.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.info_outline,
                              color: Colors.black,
                            ),
                            onPressed: () async {
                              Navigator.pop(popupMenuContext);

                              await route?.completed;
                              showUrlInfo();
                            })),
                    Container(
                        width: 30.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              _webViewController?.reload();
                              Navigator.pop(popupMenuContext);
                            })),
                  ]);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: children,
                  );
                },
              ),
            )
          ];

          items.addAll(PopupMenuActions.choices.map((choice) {
            switch (choice) {
              case PopupMenuActions.DESKTOP_MODE:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Selector<WebViewModel, bool>(
                          selector: (context, webViewModel) =>
                              webViewModel.isDesktopMode,
                          builder: (context, value, child) {
                            return Icon(
                              value
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: Colors.black54,
                            );
                          },
                        )
                      ]),
                );
              case PopupMenuActions.SHARE:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Icon(
                          Icons.share,
                          color: Colors.black54,
                        )
                      ]),
                );
              case PopupMenuActions.DEVELOPERS:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Icon(
                          Icons.computer,
                          color: Colors.black54,
                        )
                      ]),
                );
              case PopupMenuActions.FIND_ON_PAGE:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.getCurrentTab() != null,
                  value: choice,
                  child: Text(choice),
                );
              default:
                return CustomPopupMenuItem<String>(
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
        widget?.showFindOnPage();
        break;
      case PopupMenuActions.SHARE:
        share();
        break;
      case PopupMenuActions.DESKTOP_MODE:
        toggleDesktopMode();
        break;
      case PopupMenuActions.DEVELOPERS:
        goToDevelopersPage();
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
                      var faviconUrl = favorite.favicon != null
                          ? favorite.favicon.url
                          : uri.origin + "/favicon.ico";

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
                        title: Text(favorite.title ?? favorite.url,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
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
                future:
                    webViewModel?.webViewController?.getCopyBackForwardList(),
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
                            title: Text(historyItem.title ?? historyItem.url,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
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

    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: false);

    if (_webViewController != null) {
      webViewModel.isDesktopMode = !webViewModel.isDesktopMode;
      currentWebViewModel.isDesktopMode = webViewModel.isDesktopMode;

      await _webViewController.setOptions(
          options: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                  preferredContentMode: webViewModel.isDesktopMode
                      ? UserPreferredContentMode.DESKTOP
                      : UserPreferredContentMode.RECOMMENDED)));
      await _webViewController.reload();
    }
  }

  void showUrlInfo() {
    var webViewModel = Provider.of<WebViewModel>(context, listen: false);

    if (webViewModel == null) {
      return;
    }

    route = CustomPopupDialog.show(
      context: context,
      transitionDuration: customPopupDialogTransitionDuration,
      builder: (context) {
        return ShowUrlInfoPopup(
            route: route,
            transitionDuration: customPopupDialogTransitionDuration,
            onWebViewTabSettingsClicked: () {
              goToSettingsPage();
            },);
      },
    );
  }

  void goToDevelopersPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => DevelopersPage()));
  }

  void goToSettingsPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }
}
