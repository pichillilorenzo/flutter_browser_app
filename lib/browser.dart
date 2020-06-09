import 'package:flutter/material.dart';
import 'package:flutter_browser/app_bar/browser_app_bar.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import 'empty_tab.dart';
import 'models/browser_model.dart';

class Browser extends StatefulWidget {
  Browser({Key key}) : super(key: key);

  @override
  _BrowserState createState() => _BrowserState();
}

class _BrowserState extends State<Browser> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          var browserModel = Provider.of<BrowserModel>(context, listen: false);
          var webViewModel = browserModel.getCurrentTab()?.webViewModel;
          var _webViewController = webViewModel?.webViewController;

          if (_webViewController != null) {
            if (await _webViewController.canGoBack()) {
              _webViewController.goBack();
              return false;
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
        child: Scaffold(appBar: BrowserAppBar(), body: _buildWebViewTabs()));
  }

  Consumer<BrowserModel> _buildWebViewTabs() {
    return Consumer<BrowserModel>(
      builder: (context, value, child) {
        if (value.webViewTabs.length == 0) {
          return EmptyTab();
        }

        var webViewModel = value.getCurrentTab()?.webViewModel;
        if (webViewModel != null) {
          webViewModel.addListener(() {
            setState(() {});
          });
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
}
