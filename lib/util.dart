class Util {

  static bool urlIsSecure(String url) {
    return (url.startsWith("https://") ||
        Util.isLocalizedContent(url)) ?? false;
  }

  static bool isLocalizedContent(String url) {
    return (url.startsWith("file://") ||
        url.startsWith("chrome://") ||
        url.startsWith("data:") ||
        url.startsWith("javascript:") ||
        url.startsWith("about:")) ?? false;
  }

}