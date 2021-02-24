
import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/pages/settings/main.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';

import '../custom_popup_menu_item.dart';
import '../tab_viewer_popup_menu_actions.dart';

class TabViewerAppBar extends StatefulWidget implements PreferredSizeWidget {
  TabViewerAppBar({Key? key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  _TabViewerAppBarState createState() => _TabViewerAppBarState();

  @override
  final Size preferredSize;
}

class _TabViewerAppBarState extends State<TabViewerAppBar> {

  GlobalKey tabInkWellKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 10.0,
      leading: _buildAddTabButton(),
      actions: _buildActionsMenu(),
    );
  }

  Widget _buildAddTabButton() {
    return IconButton(
      icon: Icon(Icons.add),
      onPressed: () {
        addNewTab();
      },
    );
  }

  List<Widget> _buildActionsMenu() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    return <Widget>[
      InkWell(
        key: tabInkWellKey,
        onTap: () {
          if (browserModel.webViewTabs.length > 0) {
            browserModel.showTabScroller = !browserModel.showTabScroller;
          } else {
            browserModel.showTabScroller = false;
          }
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
                      browserModel
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
          var items = <PopupMenuEntry<String>>[];

          items.addAll(TabViewerPopupMenuActions.choices.map((choice) {
            switch (choice) {
              case TabViewerPopupMenuActions.NEW_TAB:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Icon(
                          Icons.add,
                          color: Colors.black,
                        )
                      ]),
                );
              case TabViewerPopupMenuActions.NEW_INCOGNITO_TAB:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Icon(
                          FlutterIcons.incognito_mco,
                          color: Colors.black,
                        )
                      ]),
                );
              case TabViewerPopupMenuActions.CLOSE_ALL_TABS:
                return CustomPopupMenuItem<String>(
                  enabled: browserModel.webViewTabs.length > 0,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Icon(
                          Icons.close,
                          color: Colors.black,
                        )
                      ]),
                );
              case TabViewerPopupMenuActions.SETTINGS:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        Icon(
                          Icons.settings,
                          color: Colors.grey,
                        )
                      ]),
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
      case TabViewerPopupMenuActions.NEW_TAB:
        Future.delayed(const Duration(milliseconds: 300), () {
          addNewTab();
        });
        break;
      case TabViewerPopupMenuActions.NEW_INCOGNITO_TAB:
        Future.delayed(const Duration(milliseconds: 300), () {
          addNewIncognitoTab();
        });
        break;
      case TabViewerPopupMenuActions.CLOSE_ALL_TABS:
        Future.delayed(const Duration(milliseconds: 300), () {
          closeAllTabs();
        });
        break;
      case TabViewerPopupMenuActions.SETTINGS:
        Future.delayed(const Duration(milliseconds: 300), () {
          goToSettingsPage();
        });
        break;
    }
  }

  void addNewTab({Uri? url}) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    if (url == null) {
      url = settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
          ? Uri.parse(settings.customUrlHomePage)
          : Uri.parse(settings.searchEngine.url);
    }

    browserModel.showTabScroller = false;

    browserModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel: WebViewModel(url: url),
    ));
  }

  void addNewIncognitoTab({Uri? url}) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    if (url == null) {
      url = settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
          ? Uri.parse(settings.customUrlHomePage)
          : Uri.parse(settings.searchEngine.url);
    }

    browserModel.showTabScroller = false;

    browserModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel:
      WebViewModel(url: url, isIncognitoMode: true),
    ));
  }

  void closeAllTabs() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    browserModel.showTabScroller = false;

    browserModel.closeAllTabs();
  }

  void goToSettingsPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }

}