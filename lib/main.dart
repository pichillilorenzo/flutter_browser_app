import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin(); // global instance

void showProgressNotification(String id, int progress) {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'adee_browser', // Channel ID
    'Adee Browser',
    channelShowBadge: false,
    importance: Importance.low,
    priority: Priority.low,
    onlyAlertOnce: true,
    showProgress: true,
    maxProgress: 100,
    progress: progress,
  );

  var platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    'Download Progress', // Title
    'Downloading file $id', // Body
    platformChannelSpecifics,
    payload: 'item x',
  );
}

void downloadCallback(String id, DownloadTaskStatus status, int progress) {
  if (kDebugMode) {
    print(
        'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
  }
  final SendPort send =
      IsolateNameServer.lookupPortByName('downloader_send_port')!;
  send.send([id, status, progress]);

  showProgressNotification(id, progress);
}

const String channelId = 'adee_browser';
const String channelName = 'Adee Browser';
const String channelDescription = 'Adee Browser';

Future<void> setupNotificationChannel() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Define Android and iOS initialization settings
  var initializationSettingsAndroid =
      const AndroidInitializationSettings('@mipmap/ic_launcher');

  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Define Android notification channel
  var androidChannel = const AndroidNotificationChannel(
    channelId,
    channelName,
    importance: Importance.high,
  );

  // Set the channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterDownloader.initialize(debug: kDebugMode, ignoreSsl: true);

  await FlutterDownloader.registerCallback(downloadCallback);

  WEB_ARCHIVE_DIR = (await getApplicationSupportDirectory()).path;

  TAB_VIEWER_BOTTOM_OFFSET_1 = 130.0;
  TAB_VIEWER_BOTTOM_OFFSET_2 = 140.0;
  TAB_VIEWER_BOTTOM_OFFSET_3 = 150.0;

  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.storage.request();

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
  setupNotificationChannel();
}

class FlutterBrowserApp extends StatelessWidget {
  const FlutterBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adee Browser',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Browser(),
      },
    );
  }
}
