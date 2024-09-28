import 'package:flutter/foundation.dart';

class Util {
  static bool urlIsSecure(Uri url) {
    return (url.scheme == "https") || Util.isLocalizedContent(url);
  }

  static bool isLocalizedContent(Uri url) {
    return (url.scheme == "file" ||
        url.scheme == "chrome" ||
        url.scheme == "data" ||
        url.scheme == "javascript" ||
        url.scheme == "about");
  }

  static bool isMobile() {
    return isAndroid() || isIOS();
  }

  static bool isAndroid() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static bool isIOS() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool isDesktop() {
    return !isMobile();
  }

  static bool isMacOS() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool isWindows() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }
}