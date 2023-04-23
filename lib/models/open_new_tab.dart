import 'package:flutter/material.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import 'browser_model.dart';
import 'webview_model.dart';

void openNewTab(value, context) {
  var browserModel = Provider.of<BrowserModel>(context, listen: false);
  var settings = browserModel.getSettings();

  browserModel.addTab(WebViewTab(
    key: GlobalKey(),
    webViewModel: WebViewModel(
        url: WebUri(value.startsWith("http")
            ? value
            : settings.searchEngine.searchUrl + value)),
  ));
}
