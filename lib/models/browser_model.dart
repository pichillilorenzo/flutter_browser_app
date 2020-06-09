import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_browser/models/favorite_model.dart';
import 'package:flutter_browser/webview_tab.dart';

import 'search_engine_model.dart';

class BrowserSettings {
  SearchEngineModel searchEngine;
  bool homePageEnabled;
  String customUrlHomePage;
  bool debuggingEnabled;

  BrowserSettings({
    this.searchEngine = GoogleSearchEngine,
    this.homePageEnabled = false,
    this.customUrlHomePage = "",
    this.debuggingEnabled = false
  });

  BrowserSettings copy() {
    return BrowserSettings(
        searchEngine: searchEngine,
        homePageEnabled: homePageEnabled,
        customUrlHomePage: customUrlHomePage,
        debuggingEnabled: debuggingEnabled
    );
  }
}

class BrowserModel extends ChangeNotifier {
  List<FavoriteModel> _favorites = [];
  final List<WebViewTab> _webViewTabs = [];
  int _currentTabIndex = -1;
  BrowserSettings _settings = BrowserSettings();

  UnmodifiableListView<WebViewTab> get webViewTabs =>
      UnmodifiableListView(_webViewTabs);

  UnmodifiableListView<FavoriteModel> get favorites =>
      UnmodifiableListView(_favorites);

  void addTab(WebViewTab webViewTab) {
    _webViewTabs.add(webViewTab);
    _currentTabIndex = _webViewTabs.length - 1;
    webViewTab.webViewModel.tabIndex = _currentTabIndex;

    notifyListeners();
  }

  void closeTab(int index) {
    _webViewTabs.removeAt(index);
    _currentTabIndex = _webViewTabs.length - 1;

    for (int i = index; i < _webViewTabs.length; i++) {
      _webViewTabs[i].webViewModel.tabIndex = i;
    }

    notifyListeners();
  }

  void showTab(int index) {
    _currentTabIndex = index;

    notifyListeners();
  }

  void closeAllTabs() {
    _webViewTabs.clear();
    _currentTabIndex = -1;

    notifyListeners();
  }

  int getCurrentTabIndex() {
    return _currentTabIndex;
  }

  WebViewTab getCurrentTab() {
    return _currentTabIndex >= 0 ? _webViewTabs[_currentTabIndex] : null;
  }

  bool containsFavorite(FavoriteModel favorite) {
    return _favorites.contains(favorite) || _favorites.firstWhere((element) => element.url == favorite.url, orElse: () => null) != null;
  }

  void addFavorite(FavoriteModel favorite) {
    _favorites.add(favorite);

    notifyListeners();
  }

  void removeFavorite(FavoriteModel favorite) {
    if (!_favorites.remove(favorite)) {
      var favToRemove = _favorites.firstWhere((element) => element.url == favorite.url, orElse: () => null);
      if (favToRemove != null) {
        _favorites.remove(favToRemove);
      }
    }

    notifyListeners();
  }

  BrowserSettings getSettings() {
    return _settings.copy();
  }

  void updateSettings(BrowserSettings settings) {
    _settings = settings;

    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }
}
