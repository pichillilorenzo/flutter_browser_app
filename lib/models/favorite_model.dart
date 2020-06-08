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
}