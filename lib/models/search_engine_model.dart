import 'package:flutter/foundation.dart';

class SearchEngineModel {
  final String name;
  final String assetIcon;
  final String url;
  final String searchUrl;

  const SearchEngineModel({
    @required this.name,
    @required this.url,
    @required this.searchUrl,
    @required this.assetIcon
  });
}

const GoogleSearchEngine = const SearchEngineModel(
  name: "Google",
  url: "https://www.google.com/",
  searchUrl: "https://www.google.com/search?q=",
  assetIcon: "assets/images/google_logo.png"
);

const YahooSearchEngine = const SearchEngineModel(
    name: "Yahoo",
    url: "https://yahoo.com/",
    searchUrl: "https://search.yahoo.com/search?p=",
    assetIcon: "assets/images/yahoo_logo.png"
);

const SearchEngines = <SearchEngineModel>[
  GoogleSearchEngine,
  YahooSearchEngine
];