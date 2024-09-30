import 'package:flutter_browser/util.dart';

class PopupMenuActions {
  // ignore: constant_identifier_names
  static const String OPEN_NEW_WINDOW = "Open New Window";
  // ignore: constant_identifier_names
  static const String SAVE_WINDOW = "Save Window";
  // ignore: constant_identifier_names
  static const String SAVED_WINDOWS = "Saved Windows";
  // ignore: constant_identifier_names
  static const String NEW_TAB = "New tab";
  // ignore: constant_identifier_names
  static const String NEW_INCOGNITO_TAB = "New incognito tab";
  // ignore: constant_identifier_names
  static const String FAVORITES = "Favorites";
  // ignore: constant_identifier_names
  static const String HISTORY = "History";
  // ignore: constant_identifier_names
  static const String WEB_ARCHIVES = "Web Archives";
  // ignore: constant_identifier_names
  static const String SHARE = "Share";
  // ignore: constant_identifier_names
  static const String FIND_ON_PAGE = "Find on page";
  // ignore: constant_identifier_names
  static const String DESKTOP_MODE = "Desktop mode";
  // ignore: constant_identifier_names
  static const String SETTINGS = "Settings";
  // ignore: constant_identifier_names
  static const String DEVELOPERS = "Developers";
  // ignore: constant_identifier_names
  static const String INAPPWEBVIEW_PROJECT = "InAppWebView Project";

  static List<String> get choices {
    if (Util.isMobile()) {
      return [
        NEW_TAB,
        NEW_INCOGNITO_TAB,
        FAVORITES,
        HISTORY,
        WEB_ARCHIVES,
        SHARE,
        FIND_ON_PAGE,
        SETTINGS,
        DEVELOPERS,
        INAPPWEBVIEW_PROJECT
      ];
    }
    return [
      OPEN_NEW_WINDOW,
      SAVE_WINDOW,
      SAVED_WINDOWS,
      NEW_TAB,
      NEW_INCOGNITO_TAB,
      FAVORITES,
      HISTORY,
      WEB_ARCHIVES,
      SHARE,
      FIND_ON_PAGE,
      SETTINGS,
      DEVELOPERS,
      INAPPWEBVIEW_PROJECT
    ];
}
}
