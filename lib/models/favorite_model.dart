import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FavoriteModel {
  String url;
  String title;
  Favicon favicon;

  FavoriteModel({
    this.url,
    this.title,
    this.favicon
  });

  static FavoriteModel fromMap(Map<String, dynamic> map) {
    return map != null ? FavoriteModel(
      url: map["url"],
      title: map["title"],
      favicon: map["favicon"] != null ? Favicon(
        url: map["favicon"]["url"],
        rel: map["favicon"]["rel"],
        width: map["favicon"]["width"],
        height: map["favicon"]["height"],
      ) : null
    ) : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "url": url,
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