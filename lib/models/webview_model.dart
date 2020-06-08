import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewModel extends ChangeNotifier {

  int _tabIndex;
  String _url;
  String _title;
  Favicon _favicon;
  double _progress;
  bool _loaded;
  bool _isDesktopMode;
  bool _isIncognitoMode;
  InAppWebViewGroupOptions _options;
  InAppWebViewController webViewController;

  WebViewModel({
    tabIndex,
    url,
    title,
    favicon,
    progress = 0.0,
    loaded = false,
    isDesktopMode = false,
    isIncognitoMode = false,
    options,
    this.webViewController,
  }) {
    this._tabIndex = tabIndex;
    this._url = url;
    this._title = title;
    this._favicon = favicon;
    this._progress = progress;
    this._loaded = loaded;
    this._isDesktopMode = isDesktopMode;
    this._isIncognitoMode = isIncognitoMode;
    this._options = options ?? InAppWebViewGroupOptions();
  }

  int get tabIndex => _tabIndex;

  set tabIndex(int value) {
    _tabIndex = value;

    notifyListeners();
  }

  String get url => _url;

  set url(String value) {
    _url = value;

    notifyListeners();
  }

  String get title => _title;

  set title(String value) {
    _title = value;

    notifyListeners();
  }

  Favicon get favicon => _favicon;

  set favicon(Favicon value) {
    _favicon = value;

    notifyListeners();
  }

  double get progress => _progress;

  set progress(double value) {
    _progress = value;

    notifyListeners();
  }

  bool get loaded => _loaded;

  set loaded(bool value) {
    _loaded = value;

    notifyListeners();
  }

  bool get isDesktopMode => _isDesktopMode;

  set isDesktopMode(bool value) {
    _isDesktopMode = value;

    notifyListeners();
  }

  bool get isIncognitoMode => _isIncognitoMode;

  set isIncognitoMode(bool value) {
    _isIncognitoMode = value;

    notifyListeners();
  }

  InAppWebViewGroupOptions get options => _options;

  set options(InAppWebViewGroupOptions value) {
    _options = value;

    notifyListeners();
  }
}