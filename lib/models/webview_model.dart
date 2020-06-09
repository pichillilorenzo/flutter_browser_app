import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewModel extends ChangeNotifier {

  int tabIndex;
  String url;
  String title;
  Favicon favicon;
  double progress;
  bool loaded;
  bool isDesktopMode;
  bool isIncognitoMode;
  List<RichText> javaScriptConsoleResults;
  List<String> javaScriptConsoleHistory;
  List<LoadedResource> loadedResources;
  InAppWebViewGroupOptions options;
  InAppWebViewController webViewController;

  WebViewModel({
    this.tabIndex,
    this.url,
    this.title,
    this.favicon,
    this.progress = 0.0,
    this.loaded = false,
    this.isDesktopMode = false,
    this.isIncognitoMode = false,
    this.javaScriptConsoleResults,
    this.javaScriptConsoleHistory,
    this.loadedResources,
    this.options,
    this.webViewController,
  }) {
    options = options ?? InAppWebViewGroupOptions();
    javaScriptConsoleResults = javaScriptConsoleResults ?? [];
    javaScriptConsoleHistory = javaScriptConsoleHistory ?? [];
    loadedResources = loadedResources ?? [];
  }
}