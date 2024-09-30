import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/pages/settings/main.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../custom_popup_menu_item.dart';
import '../models/window_model.dart';
import '../tab_viewer_popup_menu_actions.dart';

class TabViewerAppBar extends StatefulWidget implements PreferredSizeWidget {
  const TabViewerAppBar({super.key})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  State<TabViewerAppBar> createState() => _TabViewerAppBarState();

  @override
  final Size preferredSize;
}

class _TabViewerAppBarState extends State<TabViewerAppBar> {
  GlobalKey tabInkWellKey = GlobalKey();

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
      icon: const Icon(Icons.add),
      onPressed: () {
        addNewTab();
      },
    );
  }

  List<Widget> _buildActionsMenu() {
    final browserModel = Provider.of<BrowserModel>(context, listen: true);
    final windowModel = Provider.of<WindowModel>(context, listen: true);
    final settings = browserModel.getSettings();

    return <Widget>[
      InkWell(
        key: tabInkWellKey,
        onTap: () {
          if (windowModel.webViewTabs.isNotEmpty) {
            browserModel.showTabScroller = !browserModel.showTabScroller;
          } else {
            browserModel.showTabScroller = false;
          }
        },
        child: Padding(
          padding: settings.homePageEnabled
              ? const EdgeInsets.only(
                  left: 20.0, top: 15.0, right: 10.0, bottom: 15.0)
              : const EdgeInsets.only(
                  left: 10.0, top: 15.0, right: 10.0, bottom: 15.0),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(width: 2.0),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0)),
            constraints: const BoxConstraints(minWidth: 25.0),
            child: Center(
                child: Text(
                  windowModel.webViewTabs.length.toString(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0),
            )),
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
                        const Icon(
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
                        const Icon(
                          MaterialCommunityIcons.incognito,
                          color: Colors.black,
                        )
                      ]),
                );
              case TabViewerPopupMenuActions.CLOSE_ALL_TABS:
                return CustomPopupMenuItem<String>(
                  enabled: windowModel.webViewTabs.isNotEmpty,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(choice),
                        const Icon(
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
                        const Icon(
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

  void addNewTab({WebUri? url}) {
    final browserModel = Provider.of<BrowserModel>(context, listen: false);
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final settings = browserModel.getSettings();

    url ??= settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
        ? WebUri(settings.customUrlHomePage)
        : WebUri(settings.searchEngine.url);

    browserModel.showTabScroller = false;

    windowModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel: WebViewModel(url: url),
    ));
  }

  void addNewIncognitoTab({WebUri? url}) {
    final browserModel = Provider.of<BrowserModel>(context, listen: false);
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final settings = browserModel.getSettings();

    url ??= settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
        ? WebUri(settings.customUrlHomePage)
        : WebUri(settings.searchEngine.url);

    browserModel.showTabScroller = false;

    windowModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel: WebViewModel(url: url, isIncognitoMode: true),
    ));
  }

  void closeAllTabs() {
    final browserModel = Provider.of<BrowserModel>(context, listen: false);
    final windowModel = Provider.of<WindowModel>(context, listen: false);

    browserModel.showTabScroller = false;

    windowModel.closeAllTabs();
  }

  void goToSettingsPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const SettingsPage()));
  }
}
