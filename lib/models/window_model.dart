import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_browser/main.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

import '../util.dart';

class WindowModel extends ChangeNotifier {
  String _id;
  String _name = '';
  DateTime _updatedTime;
  final DateTime _createdTime;
  final List<WebViewTab> _webViewTabs = [];
  int _currentTabIndex = -1;
  late WebViewModel _currentWebViewModel;
  bool _shouldSave = false;
  bool _showTabScroller = false;

  bool get showTabScroller => _showTabScroller;

  set showTabScroller(bool value) {
    if (value != _showTabScroller) {
      _showTabScroller = value;
      notifyListeners();
    }
  }

  bool get shouldSave => _shouldSave;

  set shouldSave(bool value) {
    _shouldSave = value;
    if (_shouldSave) {
      saveInfo();
    } else {
      removeInfo();
    }
    notifyListeners();
  }

  DateTime get createdTime => _createdTime;

  DateTime get updatedTime => _updatedTime;

  WindowModel(
      {String? id,
      String? name,
      bool? shouldSave,
      DateTime? updatedTime,
      DateTime? createdTime})
      : _id = id ?? 'window_${const Uuid().v4()}',
        _name = name ?? '',
        _shouldSave = Util.isMobile() ? true : (shouldSave ?? false),
        _createdTime = createdTime ?? DateTime.now(),
        _updatedTime = updatedTime ?? DateTime.now() {
    _currentWebViewModel = WebViewModel();
  }

  String get id => _id;

  UnmodifiableListView<WebViewTab> get webViewTabs =>
      UnmodifiableListView(_webViewTabs);

  String get name => _name;

  set name(String value) {
    _name = value;

    notifyListeners();
  }

  void addTab(WebViewTab webViewTab) {
    _webViewTabs.add(webViewTab);
    _currentTabIndex = _webViewTabs.length - 1;
    webViewTab.webViewModel.tabIndex = _currentTabIndex;
    webViewTab.webViewModel.lastOpenedTime = DateTime.now();

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
      webViewTabs.last.webViewModel.lastOpenedTime = DateTime.now();
      _currentWebViewModel.updateWithValue(webViewTabs.last.webViewModel);
    }

    notifyListeners();
  }

  void closeTab(int index) {
    final webViewTab = _webViewTabs[index];
    _webViewTabs.removeAt(index);
    InAppWebViewController.disposeKeepAlive(webViewTab.webViewModel.keepAlive);

    if (Util.isMobile() || _currentTabIndex >= _webViewTabs.length) {
      _currentTabIndex = _webViewTabs.length - 1;
    }

    for (int i = index; i < _webViewTabs.length; i++) {
      _webViewTabs[i].webViewModel.tabIndex = i;
    }

    if (_currentTabIndex >= 0) {
      _currentWebViewModel
          .updateWithValue(_webViewTabs[_currentTabIndex].webViewModel);
    } else {
      _currentWebViewModel.updateWithValue(WebViewModel());
    }

    notifyListeners();
  }

  void showTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      final webViewModel = _webViewTabs[_currentTabIndex].webViewModel;
      webViewModel.lastOpenedTime = DateTime.now();
      _currentWebViewModel.updateWithValue(webViewModel);

      notifyListeners();
    }
  }

  void closeAllTabs() {
    for (final webViewTab in _webViewTabs) {
      InAppWebViewController.disposeKeepAlive(
          webViewTab.webViewModel.keepAlive);
    }
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

  void notifyWebViewTabUpdated() {
    notifyListeners();
  }

  void setCurrentWebViewModel(WebViewModel webViewModel) {
    _currentWebViewModel = webViewModel;
  }

  DateTime _lastTrySave = DateTime.now();
  Timer? _timerSave;

  Future<void> saveInfo() async {
    _timerSave?.cancel();

    if (!_shouldSave) {
      return;
    }

    if (DateTime.now().difference(_lastTrySave) >=
        const Duration(milliseconds: 400)) {
      _lastTrySave = DateTime.now();
      await flushInfo();
    } else {
      _lastTrySave = DateTime.now();
      _timerSave = Timer(const Duration(milliseconds: 500), () {
        saveInfo();
      });
    }
  }

  Future<void> removeInfo() async {
    final count = await db?.rawDelete('DELETE FROM windows WHERE id = ?', [id]);
    if ((count == null || count == 0) && kDebugMode) {
      print("Cannot delete window $id");
    }
  }

  Future<void> flushInfo() async {
    if (!_shouldSave) {
      return;
    }
    _updatedTime = DateTime.now();
    final window =
        await db?.rawQuery('SELECT * FROM windows WHERE id = ?', [id]);
    int? count;
    if (window == null || window.isEmpty) {
      count = await db?.rawInsert('INSERT INTO windows(id, json) VALUES(?, ?)',
          [id, json.encode(toJson())]);
    } else {
      count = await db?.rawUpdate('UPDATE windows SET json = ? WHERE id = ?',
          [json.encode(toJson()), id]);
    }
    if ((count == null || count == 0) && kDebugMode) {
      print("Cannot insert/update window $id");
    }
  }

  Future<void> restoreInfo() async {
    try {
      List<Map<String, Object?>>? windows;

      if (Util.isDesktop()) {
        if (windowModelId != null) {
          windows = await db
              ?.rawQuery('SELECT * FROM windows WHERE id = ?', [windowModelId]);
        } else {
          return;
        }
      } else {
        windows = await db?.rawQuery('SELECT * FROM windows');
      }

      if (windows == null || windows.isEmpty) {
        return;
      }

      final w = windows[0];
      _id = w['id'] as String;

      final source = w['json'] as String;
      final browserData = json.decode(source);

      _shouldSave = browserData["shouldSave"] ?? false;

      closeAllTabs();

      List<Map<String, dynamic>> webViewTabList =
          browserData["webViewTabs"]?.cast<Map<String, dynamic>>() ?? [];
      List<WebViewTab> webViewTabs = webViewTabList
          .map((e) => WebViewTab(
                key: GlobalKey(),
                webViewModel: WebViewModel.fromMap(e)!,
              ))
          .toList();
      webViewTabs.sort((a, b) =>
          a.webViewModel.tabIndex!.compareTo(b.webViewModel.tabIndex!));

      addTabs(webViewTabs);

      int currentTabIndex = browserData["currentTabIndex"] ?? _currentTabIndex;
      currentTabIndex = min(currentTabIndex, _webViewTabs.length - 1);

      if (currentTabIndex >= 0) {
        showTab(currentTabIndex);
      }

      await flushInfo();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return;
    }
  }

  static WindowModel fromMap(Map<String, dynamic> map) {
    final window = WindowModel(
        id: map["id"],
        name: map["name"],
        shouldSave: map["shouldSave"],
        updatedTime: map["updatedTime"] != null
            ? DateTime.tryParse(map["updatedTime"])
            : null,
        createdTime: map["createdTime"] != null
            ? DateTime.tryParse(map["createdTime"])
            : null);
    List<Map<String, dynamic>> webViewTabList =
        map["webViewTabs"]?.cast<Map<String, dynamic>>() ?? [];
    List<WebViewTab> webViewTabs = webViewTabList
        .map((e) => WebViewTab(
              key: GlobalKey(),
              webViewModel: WebViewModel.fromMap(e)!,
            ))
        .toList();
    webViewTabs.sort(
        (a, b) => a.webViewModel.tabIndex!.compareTo(b.webViewModel.tabIndex!));
    window.addTabs(webViewTabs);
    return window;
  }

  Map<String, dynamic> toMap() {
    return {
      "id": _id,
      "name": _name,
      "webViewTabs": _webViewTabs.map((e) => e.webViewModel.toMap()).toList(),
      "currentTabIndex": _currentTabIndex,
      "currentWebViewModel": _currentWebViewModel.toMap(),
      "shouldSave": _shouldSave,
      "updatedTime": _updatedTime.toIso8601String(),
      "createdTime": _createdTime.toIso8601String()
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
