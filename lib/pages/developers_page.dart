import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import '../javascript_console_result.dart';

class DevelopersPage extends StatefulWidget {
  DevelopersPage({Key key}) : super(key: key);

  @override
  _DevelopersPageState createState() => _DevelopersPageState();
}

class _DevelopersPageState extends State<DevelopersPage> {
  TextEditingController _customJavaScriptController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  CookieManager _cookieManager = CookieManager.instance();
  WebStorageManager _webStorageManager = WebStorageManager.instance();
  HttpAuthCredentialDatabase _httpAuthCredentialDatabase =
      HttpAuthCredentialDatabase.instance();

  int currentJavaScriptHistory = 0;

  var cookieNameTrackingEdit = <bool>[];
  var cookieValueTrackingEdit = <bool>[];
  var localStorageKeyTrackingEdit = <bool>[];
  var localStorageValueTrackingEdit = <bool>[];
  var sessionStorageKeyTrackingEdit = <bool>[];
  var sessionStorageValueTrackingEdit = <bool>[];

  TextEditingController _newCookieNameController = TextEditingController();
  TextEditingController _newCookieValueController = TextEditingController();
  TextEditingController _newCookiePathController = TextEditingController();
  TextEditingController _newCookieDomainController = TextEditingController();

  TextEditingController _newLocalStorageKeyController = TextEditingController();
  TextEditingController _newLocalStorageValueController =
      TextEditingController();

  TextEditingController _newSessionStorageKeyController =
      TextEditingController();
  TextEditingController _newSessionStorageValueController =
      TextEditingController();

  bool _newCookieIsSecure = false;
  DateTime _newCookieExpiresDate;

  final _newCookieFormKey = GlobalKey<FormState>();
  final _newLocalStorageItemFormKey = GlobalKey<FormState>();
  final _newSessionStorageItemFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _newCookiePathController.text = "/";
  }

  @override
  void dispose() {
    _customJavaScriptController.dispose();
    _scrollController.dispose();
    _newCookieNameController.dispose();
    _newCookieValueController.dispose();
    _newCookiePathController.dispose();
    _newCookieDomainController.dispose();
    _newLocalStorageKeyController.dispose();
    _newLocalStorageValueController.dispose();
    _newSessionStorageKeyController.dispose();
    _newSessionStorageValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            onTap: (value) {
              FocusScope.of(context).unfocus();
              cookieNameTrackingEdit = [];
              cookieValueTrackingEdit = [];
              localStorageKeyTrackingEdit = [];
              localStorageValueTrackingEdit = [];
              sessionStorageKeyTrackingEdit = [];
              sessionStorageValueTrackingEdit = [];
            },
            tabs: [
              Tab(
                icon: Icon(Icons.code),
                text: "JavaScript Console",
              ),
              Tab(
                icon: Icon(Icons.network_check),
                text: "Network",
              ),
              Tab(
                icon: Icon(Icons.storage),
                text: "Storage",
              ),
            ],
          ),
          title: Text('Developers'),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildJavaScriptConsoleTab(),
            _buildNetworkTab(),
            _buildStorageTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildJavaScriptConsoleTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Flexible(
          child: Selector<WebViewModel, List<Widget>>(
            selector: (context, webViewModel) =>
                webViewModel.javaScriptConsoleResults,
            builder: (context, javaScriptConsoleResults, child) {
              return ListView.builder(
                controller: _scrollController,
                itemCount: javaScriptConsoleResults.length,
                itemBuilder: (context, index) {
                  return javaScriptConsoleResults[index];
                },
              );
            },
          ),
        ),
        Divider(),
        Container(
          height: 75.0,
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  expands: true,
                  onSubmitted: (value) {
                    evaluateJavaScript(value);
                  },
                  controller: _customJavaScriptController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                      hintText: "document.querySelector('body') ...",
                      prefixIcon:
                          Icon(Icons.keyboard_arrow_right, color: Colors.blue),
                      border: InputBorder.none),
                ),
              ),
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () {
                  evaluateJavaScript(_customJavaScriptController.text);
                },
              ),
              Selector<WebViewModel, List<String>>(
                  selector: (context, webViewModel) =>
                      webViewModel.javaScriptConsoleHistory,
                  builder: (context, javaScriptConsoleHistory, child) {
                    currentJavaScriptHistory = javaScriptConsoleHistory.length;

                    return Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        SizedBox(
                          height: 35.0,
                          child: IconButton(
                            icon: Icon(Icons.keyboard_arrow_up),
                            onPressed: () {
                              currentJavaScriptHistory--;
                              if (currentJavaScriptHistory < 0) {
                                currentJavaScriptHistory = 0;
                              } else {
                                _customJavaScriptController.text =
                                    javaScriptConsoleHistory[
                                        currentJavaScriptHistory];
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          height: 35.0,
                          child: IconButton(
                            icon: Icon(Icons.keyboard_arrow_down),
                            onPressed: () {
                              if (currentJavaScriptHistory + 1 >=
                                  javaScriptConsoleHistory.length) {
                                currentJavaScriptHistory =
                                    javaScriptConsoleHistory.length;
                                _customJavaScriptController.text = "";
                              } else {
                                currentJavaScriptHistory++;
                                _customJavaScriptController.text =
                                    javaScriptConsoleHistory[
                                        currentJavaScriptHistory];
                              }
                            },
                          ),
                        )
                      ],
                    );
                  }),
              IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () {
                  var browserModel =
                      Provider.of<BrowserModel>(context, listen: false);
                  var webViewModel = browserModel.getCurrentTab().webViewModel;
                  webViewModel.setJavaScriptConsoleResults([]);

                  var currentWebViewModel =
                      Provider.of<WebViewModel>(context, listen: false);
                  currentWebViewModel.updateWithValue(webViewModel);
                },
              )
            ],
          ),
        )
      ],
    );
  }

  void evaluateJavaScript(String source) async {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab().webViewModel;

    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: false);

    if (source.isNotEmpty &&
        (webViewModel.javaScriptConsoleHistory.length == 0 ||
            (webViewModel.javaScriptConsoleHistory.length > 0 &&
                webViewModel.javaScriptConsoleHistory.last != source))) {
      webViewModel.addJavaScriptConsoleHistory(source);
      currentWebViewModel.updateWithValue(webViewModel);
    }

    var result =
        await webViewModel.webViewController.evaluateJavascript(source: source);

    webViewModel.addJavaScriptConsoleResults(
        JavaScriptConsoleResult(data: result.toString()));
    currentWebViewModel.updateWithValue(webViewModel);

    setState(() {
      Future.delayed(const Duration(milliseconds: 100), () async {
        await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.ease);
        // must be repeated, otherwise it won't scroll to the bottom sometimes
        await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.ease);
      });
    });
  }

  Widget _buildNetworkTab() {
    return LayoutBuilder(builder: (context, constraints) {
      return Selector<WebViewModel, List<LoadedResource>>(
          selector: (context, webViewModel) => webViewModel.loadedResources,
          builder: (context, loadedResources, child) {
            var textStyle = TextStyle(fontSize: 14.0);

            var listViewChildren = <Widget>[
              Container(
                height: 200.0,
                padding: EdgeInsets.only(left: 10.0),
                child: charts.ScatterPlotChart(
                    _createChartData(loadedResources),
                    animate: false,
                    behaviors: [
                      charts.SlidingViewport(),
                      charts.PanAndZoomBehavior(),
                    ],
                    defaultRenderer:
                        charts.PointRendererConfig(pointRendererDecorators: [
                      charts.ComparisonPointsDecorator(
                          symbolRenderer: charts.CylinderSymbolRenderer())
                    ])),
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: constraints.maxWidth / 3.0,
                    alignment: Alignment.center,
                    child: const Text(
                      "Name",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ),
                  Container(
                    width: constraints.maxWidth / 4,
                    alignment: Alignment.center,
                    child: const Text(
                      "Domain",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ),
                  Container(
                    width: constraints.maxWidth / 4,
                    alignment: Alignment.center,
                    child: const Text(
                      "Type",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        "Time",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                    ),
                  ),
                ],
              )
            ];

            listViewChildren
                .addAll(loadedResources.reversed.map((loadedResoruce) {
              var uri = Uri.parse(loadedResoruce.url);
              String path = uri.path;
              String resourceName = path.substring(path.lastIndexOf('/') + 1);

              String domain = uri.host.replaceFirst("www.", "");

              IconData iconData;
              switch (loadedResoruce.initiatorType) {
                case "script":
                  iconData = Icons.format_align_left;
                  break;
                case "css":
                  iconData = Icons.color_lens;
                  break;
                case "xmlhttprequest":
                  iconData = Icons.http;
                  break;
                case "link":
                  iconData = Icons.link;
                  break;
                default:
                  iconData = Icons.insert_drive_file;
              }

              return Row(children: <Widget>[
                InkWell(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: loadedResoruce.url));
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 5.0, horizontal: 2.5),
                      width: constraints.maxWidth / 3.0,
                      child: Row(
                        children: <Widget>[
                          loadedResoruce.initiatorType == 'img'
                              ? CachedNetworkImage(
                                  imageUrl: loadedResoruce.url,
                                  width: 20.0,
                                  errorWidget: (context, url, error) {
                                    return Icon(
                                      Icons.broken_image,
                                      size: 20.0,
                                    );
                                  },
                                )
                              : Icon(
                                  iconData,
                                  size: 20.0,
                                ),
                          SizedBox(
                            width: 10.0,
                          ),
                          Expanded(
                            child: Text(
                              resourceName,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle,
                            ),
                          )
                        ],
                      ),
                    )),
                Container(
                  width: constraints.maxWidth / 4,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 2.5),
                  child: Text(domain,
                      overflow: TextOverflow.ellipsis, style: textStyle),
                ),
                Container(
                  width: constraints.maxWidth / 4,
                  padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 2.5),
                  alignment: Alignment.center,
                  child: Text(loadedResoruce.initiatorType, style: textStyle),
                ),
                Flexible(
                    child: Container(
                  padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 2.5),
                  child: Text(
                      loadedResoruce.duration.toStringAsFixed(2) + " ms",
                      style: textStyle),
                ))
              ]);
            }).toList());

            return ListView.builder(
              itemCount: listViewChildren.length,
              itemBuilder: (context, index) {
                return listViewChildren[index];
              },
            );
          });
    });
  }

  List<charts.Series> seriesList;

  /// Create one series with sample hard coded data.
  static List<charts.Series<LoadedResource, double>> _createChartData(
      List<LoadedResource> data) {
    return [
      new charts.Series<LoadedResource, double>(
        id: 'LoadedResource',
        // Providing a color function is optional.
        colorFn: (LoadedResource loadedResource, _) {
          return charts.Color(
            r: ((loadedResource.startTime + loadedResource.duration) * 0xFFFFFF)
                .toInt(),
            b: (loadedResource.startTime * 0xFFFFFF).toInt(),
            g: (loadedResource.duration * 0xFFFFFF).toInt(),
          );
        },
        domainFn: (LoadedResource loadedResource, _) =>
            loadedResource.startTime + loadedResource.duration,
        domainLowerBoundFn: (LoadedResource loadedResource, _) =>
            loadedResource.startTime,
        domainUpperBoundFn: (LoadedResource loadedResource, _) =>
            loadedResource.startTime + loadedResource.duration,
        measureFn: (LoadedResource loadedResource, _) =>
            data.indexOf(loadedResource),
        measureLowerBoundFn: (LoadedResource loadedResource, _) =>
            loadedResource.duration,
        measureUpperBoundFn: (LoadedResource loadedResource, _) =>
            loadedResource.duration,
        radiusPxFn: (LoadedResource loadedResource, _) => 2,
        data: data,
      )
    ];
  }

  Widget _buildStorageTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        var entryItems = <Widget>[
          _buildCookiesExpansionTile(constraints),
          _buildWebLocalStorageExpansionTile(constraints),
          _buildWebSessionStorageExpansionTile(constraints),
          _buildHttpAuthCredentialDatabaseExpansionTile(constraints),
        ];

        if (Platform.isAndroid) {
          entryItems.add(_buildAndroidWebStorageExpansionTile(constraints));
        }

        return ListView.builder(
          itemCount: entryItems.length,
          itemBuilder: (context, index) {
            return entryItems[index];
          },
        );
      },
    );
  }

  Widget _buildCookiesExpansionTile(BoxConstraints constraints) {
    return Selector<WebViewModel, String>(
      selector: (context, webViewModel) => webViewModel.url,
      builder: (context, url, child) {
        return FutureBuilder(
          future: _cookieManager.getCookies(url: url),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            List<Cookie> cookies = snapshot.data;

            var rows = <DataRow>[];
            if (cookieValueTrackingEdit.length != cookies.length) {
              cookieNameTrackingEdit = List.filled(cookies.length, false);
              cookieValueTrackingEdit = List.filled(cookies.length, false);
            }

            rows.addAll(cookies.map((cookie) {
              var index = cookies.indexOf(cookie);
              return DataRow(cells: <DataCell>[
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      var updateCookie = await _cookieManager.getCookie(
                          url: url, name: cookie.name);
                      await _cookieManager.deleteCookie(
                          url: url, name: cookie.name);
                      await _cookieManager.setCookie(
                          url: url,
                          name: cookie.name,
                          value: updateCookie.value);
                    },
                    initialValue: cookie.name,
                    index: index,
                    trackingEditStatus: cookieNameTrackingEdit),
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      await _cookieManager.setCookie(
                          url: url, name: cookie.name, value: newValue);
                    },
                    initialValue: cookie.value,
                    index: index,
                    trackingEditStatus: cookieValueTrackingEdit),
                DataCell(IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      _cookieManager.deleteCookie(url: url, name: cookie.name);
                    });
                  },
                ))
              ]);
            }).toList());

            return ExpansionTile(
              onExpansionChanged: (value) {
                FocusScope.of(context).unfocus();
              },
              title: const Text(
                "Cookies",
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              children: <Widget>[
                Container(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: const Text(
                          "Name",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Value",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Delete",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                    ],
                    rows: rows,
                  ),
                ),
                Form(
                  key: _newCookieFormKey,
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(right: 10.0),
                                child: TextFormField(
                                  controller: _newCookieNameController,
                                  decoration:
                                      InputDecoration(labelText: "Cookie Name"),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please enter some text';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                child: TextFormField(
                                  controller: _newCookieValueController,
                                  decoration: InputDecoration(
                                      labelText: "Cookie Value"),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please enter some text';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(right: 10.0),
                                child: TextFormField(
                                  controller: _newCookieDomainController,
                                  decoration: InputDecoration(
                                      labelText: "Cookie Domain"),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                child: TextFormField(
                                  controller: _newCookiePathController,
                                  decoration:
                                      InputDecoration(labelText: "Cookie Path"),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please enter some text';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Container(
                                      child: ListTile(
                                        title: Text("Expires in:"),
                                        subtitle: Text(
                                            _newCookieExpiresDate != null
                                                ? _newCookieExpiresDate
                                                    .toIso8601String()
                                                : "Select a date ..."),
                                        onTap: () async {
                                          FocusScope.of(context).unfocus();
                                          DatePicker.showDateTimePicker(context,
                                              showTitleActions: true,
                                              minTime: DateTime.now(),
                                              maxTime: DateTime(9999),
                                              onConfirm: (expiresDate) {
                                            setState(() {
                                              _newCookieExpiresDate =
                                                  expiresDate;
                                            });
                                          },
                                              currentTime:
                                                  _newCookieExpiresDate);
                                        },
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _newCookieExpiresDate = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                                child: CheckboxListTile(
                              title: Text("Is Secure?"),
                              value: _newCookieIsSecure,
                              onChanged: (newValue) {
                                setState(() {
                                  _newCookieIsSecure = newValue;
                                });
                              }, //  <-- leading Checkbox
                            )),
                          ],
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width,
                            child: FlatButton(
                              padding: EdgeInsets.all(15.0),
                              child: Text("Add Cookie"),
                              onPressed: () {
                                if (_newCookieFormKey.currentState.validate()) {
                                  final expiresDate =
                                      _newCookieExpiresDate != null
                                          ? _newCookieExpiresDate
                                              .millisecondsSinceEpoch
                                          : _newCookieExpiresDate;

                                  setState(() {
                                    _cookieManager.setCookie(
                                        url: url,
                                        name: _newCookieNameController.text,
                                        value: _newCookieValueController.text,
                                        domain: _newCookieDomainController.text,
                                        isSecure: _newCookieIsSecure,
                                        path: _newCookiePathController.text,
                                        expiresDate: expiresDate);

                                    _newCookieFormKey.currentState.reset();
                                  });
                                }
                              },
                            ))
                      ],
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FlatButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("Clear cookies"),
                        onPressed: () {
                          setState(() {
                            _cookieManager.deleteCookies(url: url);
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: FlatButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("Clear all"),
                        onPressed: () {
                          setState(() {
                            _cookieManager.deleteAllCookies();
                          });
                        },
                      ),
                    )
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWebLocalStorageExpansionTile(BoxConstraints constraints) {
    return Consumer<WebViewModel>(
      builder: (context, webViewModel, child) {
        var _webViewController = webViewModel.webViewController;

        return FutureBuilder(
          future: _webViewController.webStorage.localStorage.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            List<WebStorageItem> webStorageItems = snapshot.data;

            var rows = <DataRow>[];
            if (localStorageValueTrackingEdit.length !=
                webStorageItems.length) {
              localStorageKeyTrackingEdit =
                  List.filled(webStorageItems.length, false);
              localStorageValueTrackingEdit =
                  List.filled(webStorageItems.length, false);
            }

            rows.addAll(webStorageItems.map((webStorageItem) {
              var index = webStorageItems.indexOf(webStorageItem);
              return DataRow(cells: <DataCell>[
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      var updateItemValue = await _webViewController
                          .webStorage.localStorage
                          .getItem(key: webStorageItem.key);
                      await _webViewController.webStorage.localStorage
                          .removeItem(key: webStorageItem.key);
                      await _webViewController.webStorage.localStorage
                          .setItem(key: newValue, value: updateItemValue);
                    },
                    initialValue: webStorageItem.key,
                    index: index,
                    trackingEditStatus: localStorageKeyTrackingEdit),
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      await _webViewController.webStorage.localStorage
                          .setItem(key: webStorageItem.key, value: newValue);
                    },
                    initialValue: webStorageItem.value,
                    index: index,
                    trackingEditStatus: localStorageValueTrackingEdit),
                DataCell(IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      _webViewController.webStorage.localStorage
                          .removeItem(key: webStorageItem.key);
                    });
                  },
                ))
              ]);
            }).toList());

            return ExpansionTile(
              onExpansionChanged: (value) {
                FocusScope.of(context).unfocus();
              },
              title: const Text(
                "Local Storage",
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              children: <Widget>[
                Container(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: const Text(
                          "Key",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Value",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Delete",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                    ],
                    rows: rows,
                  ),
                ),
                _buildAddNewWebStorageItem(
                  formKey: _newLocalStorageItemFormKey,
                  nameController: _newLocalStorageKeyController,
                  valueController: _newLocalStorageValueController,
                  labelName: "Local Item Key",
                  labelValue: "Local Item Value",
                  onAdded: (name, value) {
                    _webViewController.webStorage.localStorage
                        .setItem(key: name, value: value);
                  },
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: FlatButton(
                    padding: EdgeInsets.all(15.0),
                    child: Text("Clear items"),
                    onPressed: () {
                      setState(() {
                        _webViewController.webStorage.localStorage.clear();
                      });
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWebSessionStorageExpansionTile(BoxConstraints constraints) {
    return Consumer<WebViewModel>(
      builder: (context, webViewModel, child) {
        var _webViewController = webViewModel.webViewController;

        return FutureBuilder(
          future: _webViewController.webStorage.sessionStorage.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            List<WebStorageItem> webStorageItems = snapshot.data;

            var rows = <DataRow>[];

            if (sessionStorageValueTrackingEdit.length !=
                webStorageItems.length) {
              sessionStorageKeyTrackingEdit =
                  List.filled(webStorageItems.length, false);
              sessionStorageValueTrackingEdit =
                  List.filled(webStorageItems.length, false);
            }

            rows.addAll(webStorageItems.map((webStorageItem) {
              var index = webStorageItems.indexOf(webStorageItem);

              return DataRow(cells: <DataCell>[
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      var updateItemValue = await _webViewController
                          .webStorage.sessionStorage
                          .getItem(key: webStorageItem.key);
                      await _webViewController.webStorage.sessionStorage
                          .removeItem(key: webStorageItem.key);
                      await _webViewController.webStorage.sessionStorage
                          .setItem(key: newValue, value: updateItemValue);
                    },
                    initialValue: webStorageItem.key,
                    index: index,
                    trackingEditStatus: sessionStorageKeyTrackingEdit),
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      await _webViewController.webStorage.sessionStorage
                          .setItem(key: webStorageItem.key, value: newValue);
                    },
                    initialValue: webStorageItem.value,
                    index: index,
                    trackingEditStatus: sessionStorageValueTrackingEdit),
                DataCell(IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      _webViewController.webStorage.sessionStorage
                          .removeItem(key: webStorageItem.key);
                    });
                  },
                ))
              ]);
            }).toList());

            return ExpansionTile(
              onExpansionChanged: (value) {
                FocusScope.of(context).unfocus();
              },
              title: const Text(
                "Session Storage",
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              children: <Widget>[
                Container(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: const Text(
                          "Key",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Value",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Delete",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                    ],
                    rows: rows,
                  ),
                ),
                _buildAddNewWebStorageItem(
                  formKey: _newSessionStorageItemFormKey,
                  nameController: _newSessionStorageKeyController,
                  valueController: _newSessionStorageValueController,
                  labelName: "Session Item Key",
                  labelValue: "Session Item Value",
                  onAdded: (name, value) {
                    _webViewController.webStorage.sessionStorage
                        .setItem(key: name, value: value);
                  },
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: FlatButton(
                    padding: EdgeInsets.all(15.0),
                    child: Text("Clear items"),
                    onPressed: () {
                      setState(() {
                        _webViewController.webStorage.sessionStorage.clear();
                      });
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAndroidWebStorageExpansionTile(BoxConstraints constraints) {
    var children = <Widget>[
      ListTile(
        title: const Text("Quota"),
        subtitle: Selector<WebViewModel, String>(
          selector: (context, webViewModel) => webViewModel.url,
          builder: (context, url, child) {
            var uri = Uri.parse(url);

            return FutureBuilder(
              future: _webStorageManager.android
                  .getQuotaForOrigin(origin: uri.origin),
              builder: (context, snapshot) {
                return Text(snapshot.hasData ? snapshot.data.toString() : "");
              },
            );
          },
        ),
      ),
      Selector<WebViewModel, String>(
          selector: (context, webViewModel) => webViewModel.url,
          builder: (context, url, child) {
            var uri = Uri.parse(url);

            return ListTile(
              title: const Text("Usage"),
              subtitle: FutureBuilder(
                future: _webStorageManager.android
                    .getUsageForOrigin(origin: uri.origin),
                builder: (context, snapshot) {
                  return Text(snapshot.hasData ? snapshot.data.toString() : "");
                },
              ),
              trailing: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _webStorageManager.android.deleteOrigin(origin: uri.origin);
                },
              ),
            );
          }),
    ];

    return ExpansionTile(
      onExpansionChanged: (value) {
        FocusScope.of(context).unfocus();
      },
      title: const Text(
        "Web Storage Android",
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
      children: children,
    );
  }

  Widget _buildHttpAuthCredentialDatabaseExpansionTile(
      BoxConstraints constraints) {
    return Selector<WebViewModel, String>(
        selector: (context, webViewModel) => webViewModel.url,
        builder: (context, url, child) {
          var uri = Uri.parse(url);

          ProtectionSpace protectionSpace = ProtectionSpace(
              protocol: uri.scheme,
              host: uri.host,
              port: uri.port,
              realm: uri.origin);

          return FutureBuilder(
            future: _httpAuthCredentialDatabase.getHttpAuthCredentials(
                protectionSpace: protectionSpace),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }

              List<HttpAuthCredential> httpAuthCredentials = snapshot.data;

              var rows = <DataRow>[];
              var textStyle = TextStyle(fontSize: 16.0);

              rows.addAll(httpAuthCredentials.map((httpAuthCredential) {
                return DataRow(cells: <DataCell>[
                  DataCell(
                    Container(
                      width: constraints.maxWidth / 3,
                      child: Text(httpAuthCredential.username,
                          style: textStyle, softWrap: true),
                    ),
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: httpAuthCredential.username));
                    },
                  ),
                  DataCell(
                    Container(
                      width: constraints.maxWidth / 3,
                      child: Text(httpAuthCredential.password,
                          style: textStyle, softWrap: true),
                    ),
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: httpAuthCredential.password));
                    },
                  ),
                  DataCell(IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () {
                      setState(() {
                        _httpAuthCredentialDatabase.removeHttpAuthCredential(
                            protectionSpace: protectionSpace,
                            credential: httpAuthCredential);
                      });
                    },
                  ))
                ]);
              }).toList());

              return ExpansionTile(
                onExpansionChanged: (value) {
                  FocusScope.of(context).unfocus();
                },
                title: const Text(
                  "Http Auth Credential Database",
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                children: <Widget>[
                  Container(
                    width: constraints.minWidth,
                    child: DataTable(
                      columnSpacing: 0.0,
                      columns: const <DataColumn>[
                        DataColumn(
                          label: const Text(
                            "Username",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20.0),
                          ),
                        ),
                        DataColumn(
                          label: const Text(
                            "Password",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20.0),
                          ),
                        ),
                        DataColumn(
                          label: const Text(
                            "Delete",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20.0),
                          ),
                        ),
                      ],
                      rows: rows,
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FlatButton(
                          padding: EdgeInsets.all(15.0),
                          child: Text("Clear credentials"),
                          onPressed: () {
                            setState(() {
                              _httpAuthCredentialDatabase
                                  .removeHttpAuthCredentials(
                                      protectionSpace: protectionSpace);
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: FlatButton(
                          padding: EdgeInsets.all(15.0),
                          child: Text("Clear all"),
                          onPressed: () {
                            setState(() {
                              _httpAuthCredentialDatabase
                                  .clearAllAuthCredentials();
                            });
                          },
                        ),
                      )
                    ],
                  )
                ],
              );
            },
          );
        });
  }

  DataCell _buildDataCellEditable(
      {double width,
      int index,
      List<bool> trackingEditStatus,
      String initialValue,
      Future<void> Function(String newValue) onFieldSubmitted}) {
    return DataCell(
      Container(
          width: width,
          child: Builder(
            builder: (context) {
              return !trackingEditStatus[index]
                  ? Text(
                      initialValue,
                      style: TextStyle(fontSize: 16.0),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    )
                  : TextFormField(
                      initialValue: initialValue,
                      autofocus: false,
                      onFieldSubmitted: (newValue) async {
                        if (newValue != initialValue) {
                          await onFieldSubmitted(newValue);
                        }
                        setState(() {
                          trackingEditStatus[index] = false;
                        });
                      },
                    );
            },
          )),
      onTap: () {
        setState(() {
          trackingEditStatus[index] = !trackingEditStatus[index];
        });
      },
    );
  }

  Widget _buildAddNewWebStorageItem(
      {@required GlobalKey<FormState> formKey,
        @required TextEditingController nameController,
        @required  TextEditingController valueController,
        @required String labelName,
        @required String labelValue,
      Function(String name, String value) onAdded}) {
    return Form(
      key: formKey,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: labelName),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(right: 10.0),
              child: TextFormField(
                controller: valueController,
                decoration: InputDecoration(labelText: labelValue),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
            ),
          ),
          Container(
              child: FlatButton(
                padding: EdgeInsets.all(15.0),
                child: Text("Add Item"),
                onPressed: () {
                  if (formKey.currentState.validate()) {
                    setState(() {
                      onAdded(nameController.text, valueController.text);
                      formKey.currentState.reset();
                    });
                  }
                },
              )),
        ],
      ),
    );
  }
}
