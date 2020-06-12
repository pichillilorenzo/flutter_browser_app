import 'package:flutter/material.dart';
import 'package:flutter_browser/app_bar/browser_app_bar.dart';
import 'package:flutter_browser/models/webview_model.dart';
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
        child: Scaffold(appBar: BrowserAppBar(), body: SafeArea(
          child: _buildWebViewTabs(),
        )));
  }

  Consumer<BrowserModel> _buildWebViewTabs() {
    return Consumer<BrowserModel>(
      builder: (consumerContext, browserModel, child) {
        if (browserModel.webViewTabs.length == 0) {
          return EmptyTab();
        }

        var stackChildrens = <Widget>[
          IndexedStack(
            index: browserModel.getCurrentTabIndex(),
            children: browserModel.webViewTabs,
          ),
          _createProgressIndicator()
        ];

        return Stack(
          children: stackChildrens,
        );
      },
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
              preferredSize: Size(double.infinity, 4.0),
              child: SizedBox(
                  height: 4.0,
                  child: LinearProgressIndicator(
                    value: progress,
                  )));
        });
  }
}
