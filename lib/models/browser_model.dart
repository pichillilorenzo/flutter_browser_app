import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_browser/util.dart';
import 'web_archive_model.dart';
import 'window_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'favorite_model.dart';

import 'search_engine_model.dart';
import 'package:collection/collection.dart';

class BrowserSettings {
  SearchEngineModel searchEngine;
  bool homePageEnabled;
  String customUrlHomePage;
  bool debuggingEnabled;

  BrowserSettings(
      {this.searchEngine = GoogleSearchEngine,
      this.homePageEnabled = false,
      this.customUrlHomePage = "",
      this.debuggingEnabled = false});

  BrowserSettings copy() {
    return BrowserSettings(
        searchEngine: searchEngine,
        homePageEnabled: homePageEnabled,
        customUrlHomePage: customUrlHomePage,
        debuggingEnabled: debuggingEnabled);
  }

  static BrowserSettings? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? BrowserSettings(
            searchEngine: SearchEngines[map["searchEngineIndex"]],
            homePageEnabled: map["homePageEnabled"],
            customUrlHomePage: map["customUrlHomePage"],
            debuggingEnabled: map["debuggingEnabled"])
        : null;
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
  final Map<String, WebArchiveModel> _webArchives = {};
  BrowserSettings _settings = BrowserSettings();

  bool _showTabScroller = false;

  bool get showTabScroller => _showTabScroller;

  set showTabScroller(bool value) {
    if (value != _showTabScroller) {
      _showTabScroller = value;
      notifyListeners();
    }
  }

  BrowserModel() {}

  UnmodifiableListView<FavoriteModel> get favorites =>
      UnmodifiableListView(_favorites);

  UnmodifiableMapView<String, WebArchiveModel> get webArchives =>
      UnmodifiableMapView(_webArchives);

  Future<void> openWindow(WindowModel? window) async {
    if (Util.isMobile()) {
      return;
    }

    if (window != null) {
      window.waitingToBeOpened = true;
      await window.flushInfo();
    }

    if (Util.isMacOS()) {
      await Process.run('open', [
        '-n',
        '-a',
        Platform.resolvedExecutable
            .replaceFirst('/Contents/MacOS/flutter_browser_app', '')
      ]).then(
        (value) {
          if (kDebugMode) {
            print(value.pid);
            print(value.stdout);
            print(value.stderr);
          }
        },
      );
    } else if (Util.isWindows()) {
      // TODO: Implement Windows
    }

    notifyListeners();
  }

  Future<void> removeWindow(WindowModel window) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final removed = await prefs.remove(window.id);
    if (!removed && kDebugMode) {
      print("Failed to remove window '${window.id}'");
    }
  }

  Future<void> removeAllWindows() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final List<WindowModel> windows = [];
    try {
      for (final k in prefs.getKeys()) {
        if (k.startsWith('window_')) {
          final removed = await prefs.remove(k);
          if (!removed && kDebugMode) {
            print("Failed to remove window '$k'");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  bool containsFavorite(FavoriteModel favorite) {
    return _favorites.contains(favorite) ||
        _favorites
                .map((e) => e)
                .firstWhereOrNull((element) => element.url == favorite.url) !=
            null;
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
      var favToRemove = _favorites
          .map((e) => e)
          .firstWhereOrNull((element) => element.url == favorite.url);
      _favorites.remove(favToRemove);
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
      } finally {
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
        } finally {
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

  Future<List<WindowModel>> getWindows() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final List<WindowModel> windows = [];
    try {
      for (final k in prefs.getKeys()) {
        if (k.startsWith('window_')) {
          final source = prefs.getString(k);
          if (source != null) {
            Map<String, dynamic> browserData = json.decode(source);
            windows.add(WindowModel.fromMap(browserData));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return windows;
  }

  DateTime _lastTrySave = DateTime.now();
  Timer? _timerSave;

  Future<void> save() async {
    _timerSave?.cancel();

    if (DateTime.now().difference(_lastTrySave) >=
        const Duration(milliseconds: 400)) {
      _lastTrySave = DateTime.now();
      await flush();
    } else {
      _lastTrySave = DateTime.now();
      _timerSave = Timer(const Duration(milliseconds: 500), () {
        save();
      });
    }
  }

  Future<void> flush() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    await prefs.setString("browser", json.encode(toJson()));
  }

  Future<void> restore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    Map<String, dynamic> browserData;
    try {
      String? source = prefs.getString("browser");
      if (source != null) {
        browserData = await json.decode(source);

        clearFavorites();
        clearWebArchives();

        List<Map<String, dynamic>> favoritesList =
            browserData["favorites"]?.cast<Map<String, dynamic>>() ?? [];
        List<FavoriteModel> favorites =
            favoritesList.map((e) => FavoriteModel.fromMap(e)!).toList();

        Map<String, dynamic> webArchivesMap =
            browserData["webArchives"]?.cast<String, dynamic>() ?? {};
        Map<String, WebArchiveModel> webArchives = webArchivesMap.map(
            (key, value) => MapEntry(
                key, WebArchiveModel.fromMap(value?.cast<String, dynamic>())!));

        BrowserSettings settings = BrowserSettings.fromMap(
                browserData["settings"]?.cast<String, dynamic>()) ??
            BrowserSettings();

        addFavorites(favorites);
        addWebArchives(webArchives);
        updateSettings(settings);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "favorites": _favorites.map((e) => e.toMap()).toList(),
      "webArchives":
          _webArchives.map((key, value) => MapEntry(key, value.toMap())),
      "settings": _settings.toMap()
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
