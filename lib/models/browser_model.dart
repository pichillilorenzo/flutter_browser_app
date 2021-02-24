import 'dart:collection';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_browser/models/web_archive_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_browser/models/favorite_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
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

  static BrowserSettings? fromMap(Map<String, dynamic>? map) {
    return map != null ? BrowserSettings(
        searchEngine: SearchEngines[map["searchEngineIndex"]],
        homePageEnabled: map["homePageEnabled"],
        customUrlHomePage: map["customUrlHomePage"],
        debuggingEnabled: map["debuggingEnabled"]
    ) : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "searchEngineIndex": SearchEngines.indexOf(searchEngine),
      "homePageEnabled": homePageEnabled,
      "customUrlHomePage": customUrlHomePage,
      "debuggingEnabled": debuggingEnabled
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

class BrowserModel extends ChangeNotifier {
  final List<FavoriteModel> _favorites = [];
  final List<WebViewTab> _webViewTabs = [];
  final Map<String, WebArchiveModel> _webArchives = {};
  int _currentTabIndex = -1;
  BrowserSettings _settings = BrowserSettings();
  late WebViewModel _currentWebViewModel;

  bool _showTabScroller = false;

  bool get showTabScroller => _showTabScroller;

  set showTabScroller(bool value) {
    if (value != _showTabScroller) {
      _showTabScroller = value;
      notifyListeners();
    }
  }

  BrowserModel(currentWebViewModel) {
    this._currentWebViewModel = currentWebViewModel;
  }

  UnmodifiableListView<WebViewTab> get webViewTabs =>
      UnmodifiableListView(_webViewTabs);

  UnmodifiableListView<FavoriteModel> get favorites =>
      UnmodifiableListView(_favorites);

  UnmodifiableMapView<String, WebArchiveModel> get webArchives =>
      UnmodifiableMapView(_webArchives);

  void addTab(WebViewTab webViewTab) {
    _webViewTabs.add(webViewTab);
    _currentTabIndex = _webViewTabs.length - 1;
    webViewTab.webViewModel.tabIndex = _currentTabIndex;

    _currentWebViewModel.updateWithValue(webViewTab.webViewModel);

    notifyListeners();
  }

  void addTabs(List<WebViewTab> webViewTabs) {
    for (var webViewTab in webViewTabs) {
      _webViewTabs.add(webViewTab);
      webViewTab.webViewModel.tabIndex = _webViewTabs.length - 1;
    }
    _currentTabIndex = _webViewTabs.length - 1;
    if (_currentTabIndex >= 0) {
      _currentWebViewModel.updateWithValue(webViewTabs.last.webViewModel);
    }

    notifyListeners();
  }

  void closeTab(int index) {
    _webViewTabs.removeAt(index);
    _currentTabIndex = _webViewTabs.length - 1;

    for (int i = index; i < _webViewTabs.length; i++) {
      _webViewTabs[i].webViewModel.tabIndex = i;
    }

    if (_currentTabIndex >= 0) {
      _currentWebViewModel.updateWithValue(_webViewTabs[_currentTabIndex].webViewModel);
    } else {
      _currentWebViewModel.updateWithValue(WebViewModel());
    }

    notifyListeners();
  }

  void showTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      _currentWebViewModel.updateWithValue(_webViewTabs[_currentTabIndex].webViewModel);

      notifyListeners();
    }
  }

  void closeAllTabs() {
    _webViewTabs.clear();
    _currentTabIndex = -1;
    _currentWebViewModel.updateWithValue(WebViewModel());

    notifyListeners();
  }

  int getCurrentTabIndex() {
    return _currentTabIndex;
  }

  WebViewTab? getCurrentTab() {
    return _currentTabIndex >= 0 ? _webViewTabs[_currentTabIndex] : null;
  }

  bool containsFavorite(FavoriteModel favorite) {
    return _favorites.contains(favorite) || _favorites.map((e) => e as FavoriteModel?).firstWhere((element) => element!.url == favorite.url, orElse: () => null) != null;
  }

  void addFavorite(FavoriteModel favorite) {
    _favorites.add(favorite);
    notifyListeners();
  }

  void addFavorites(List<FavoriteModel> favorites) {
    _favorites.addAll(favorites);
    notifyListeners();
  }

  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }

  void removeFavorite(FavoriteModel favorite) {
    if (!_favorites.remove(favorite)) {
      var favToRemove = _favorites.map((e) => e as FavoriteModel?).firstWhere((element) => element!.url == favorite.url, orElse: () => null);
      if (favToRemove != null) {
        _favorites.remove(favToRemove);
      }
    }

    notifyListeners();
  }

  void addWebArchive(String url, WebArchiveModel webArchiveModel) {
    _webArchives.putIfAbsent(url, () => webArchiveModel);
    notifyListeners();
  }

  void addWebArchives(Map<String, WebArchiveModel> webArchives) {
    _webArchives.addAll(webArchives);
    notifyListeners();
  }

  void removeWebArchive(WebArchiveModel webArchive) {
    var path = webArchive.path;
    if (path != null) {
      final webArchiveFile = File(path);
      try {
        webArchiveFile.deleteSync();
      } catch (e) { }
      finally {
        _webArchives.remove(webArchive.url.toString());
      }
      notifyListeners();
    }
  }

  void clearWebArchives() {
    _webArchives.forEach((key, webArchive) {
      var path = webArchive.path;
      if (path != null) {
        final webArchiveFile = File(path);
        try {
          webArchiveFile.deleteSync();
        } catch (e) {}
        finally {
          _webArchives.remove(key);
        }
      }
    });

    notifyListeners();
  }

  BrowserSettings getSettings() {
    return _settings.copy();
  }

  void updateSettings(BrowserSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  void setCurrentWebViewModel(WebViewModel webViewModel) {
    _currentWebViewModel = webViewModel;
  }

  DateTime _lastTrySave = DateTime.now();
  Timer? _timerSave;
  Future<void> save() async {
    _timerSave?.cancel();

    if (DateTime.now().difference(_lastTrySave) >= Duration(milliseconds: 400)) {
      _lastTrySave = DateTime.now();
      await flush();
    } else {
      _lastTrySave = DateTime.now();
      _timerSave = Timer(Duration(milliseconds: 500), () {
        save();
      });
    }
  }

  Future<void> flush() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("browser", json.encode(toJson()));
  }

  Future<void> restore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> browserData;
    try {
      browserData = await json.decode(prefs.getString("browser"));
    } catch (e) {
      print(e);
      return;
    }

    this.clearFavorites();
    this.closeAllTabs();
    this.clearWebArchives();

    List<Map<String, dynamic>> favoritesList = browserData["favorites"]?.cast<Map<String, dynamic>>() ?? [];
    List<FavoriteModel> favorites = favoritesList.map((e) => FavoriteModel.fromMap(e)!).toList();

    Map<String, dynamic> webArchivesMap = browserData["webArchives"]?.cast<String, dynamic>() ?? {};
    Map<String, WebArchiveModel> webArchives = webArchivesMap.map((key, value) =>
        MapEntry(key, WebArchiveModel.fromMap(value?.cast<String, dynamic>())!));

    BrowserSettings settings = BrowserSettings.fromMap(browserData["settings"]?.cast<String, dynamic>()) ?? BrowserSettings();
    List<Map<String, dynamic>> webViewTabList = browserData["webViewTabs"]?.cast<Map<String, dynamic>>() ?? [];
    List<WebViewTab> webViewTabs = webViewTabList
        .map((e) => WebViewTab(
          key: GlobalKey(),
          webViewModel: WebViewModel.fromMap(e)!,
        ))
        .toList();
    webViewTabs.sort((a, b) => a.webViewModel.tabIndex!.compareTo(b.webViewModel.tabIndex!));


    this.addFavorites(favorites);
    this.addWebArchives(webArchives);
    this.updateSettings(settings);
    this.addTabs(webViewTabs);

    int currentTabIndex = browserData["currentTabIndex"] ?? this._currentTabIndex;
    currentTabIndex = min(currentTabIndex, this._webViewTabs.length - 1);

    if (currentTabIndex >= 0)
      this.showTab(currentTabIndex);
  }

  Map<String, dynamic> toMap() {
    return {
      "favorites": _favorites.map((e) => e.toMap()).toList(),
      "webViewTabs": _webViewTabs.map((e) => e.webViewModel.toMap()).toList(),
      "webArchives": _webArchives.map((key, value) => MapEntry(key, value.toMap())),
      "currentTabIndex": _currentTabIndex,
      "settings": _settings.toMap(),
      "currentWebViewModel": _currentWebViewModel.toMap(),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
