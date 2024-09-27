import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'browser.dart';

// ignore: non_constant_identifier_names
late final String WEB_ARCHIVE_DIR;
// ignore: non_constant_identifier_names
late final double TAB_VIEWER_BOTTOM_OFFSET_1;
// ignore: non_constant_identifier_names
late final double TAB_VIEWER_BOTTOM_OFFSET_2;
// ignore: non_constant_identifier_names
late final double TAB_VIEWER_BOTTOM_OFFSET_3;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_OFFSET_1 = 0.0;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_OFFSET_2 = 10.0;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_OFFSET_3 = 20.0;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_SCALE_TOP_OFFSET = 250.0;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_SCALE_BOTTOM_OFFSET = 230.0;

WebViewEnvironment? webViewEnvironment;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  WEB_ARCHIVE_DIR = (await getApplicationSupportDirectory()).path;

  TAB_VIEWER_BOTTOM_OFFSET_1 = 130.0;
  TAB_VIEWER_BOTTOM_OFFSET_2 = 140.0;
  TAB_VIEWER_BOTTOM_OFFSET_3 = 150.0;

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    assert(availableVersion != null,
    'Failed to find an installed WebView2 Runtime or non-stable Microsoft Edge installation.');

    webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(userDataFolder: 'flutter_browser_app'));
  }

  if (Util.isAndroid() || Util.isIOS()) {
    await FlutterDownloader.initialize(
        debug: kDebugMode
    );
  }

  if (Util.isAndroid() || Util.isIOS()) {
    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => WebViewModel(),
        ),
        ChangeNotifierProxyProvider<WebViewModel, BrowserModel>(
          update: (context, webViewModel, browserModel) {
            browserModel!.setCurrentWebViewModel(webViewModel);
            return browserModel;
          },
          create: (BuildContext context) => BrowserModel(),
        ),
      ],
      child: const FlutterBrowserApp(),
    ),
  );
}

class FlutterBrowserApp extends StatelessWidget {
  const FlutterBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Browser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Browser(),
      },
    );
  }
}
