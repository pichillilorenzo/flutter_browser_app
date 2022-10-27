import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FavoriteModel {
  WebUri? url;
  String? title;
  Favicon? favicon;

  FavoriteModel({required this.url, required this.title, this.favicon});

  static FavoriteModel? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? FavoriteModel(
            url: map["url"] != null ? WebUri(map["url"]) : null,
            title: map["title"],
            favicon: map["favicon"] != null
                ? Favicon(
                    url: WebUri(map["favicon"]["url"]),
                    rel: map["favicon"]["rel"],
                    width: map["favicon"]["width"],
                    height: map["favicon"]["height"],
                  )
                : null)
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "url": url?.toString(),
      "title": title,
      "favicon": favicon?.toMap()
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
