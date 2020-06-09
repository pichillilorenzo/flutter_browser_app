import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class DevelopersPage extends StatefulWidget {
  DevelopersPage({Key key}) : super(key: key);

  @override
  _DevelopersPageState createState() => _DevelopersPageState();
}

class _DevelopersPageState extends State<DevelopersPage> {
  TextEditingController _customJavaScriptController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  CookieManager _cookieManager = CookieManager.instance();

  int currentJavaScriptHistory = -1;

  @override
  void dispose() {
    _customJavaScriptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
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
    return Consumer<BrowserModel>(
      builder: (context, browserModel, child) {
        var webViewModel = browserModel.getCurrentTab().webViewModel;
        if (currentJavaScriptHistory == -1) {
          currentJavaScriptHistory =
              webViewModel.javaScriptConsoleHistory.length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Flexible(
              child: ListView(
                controller: _scrollController,
                children: webViewModel.javaScriptConsoleResults
                    .map((javaScriptResult) {
                  return Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    child: javaScriptResult,
                  );
                }).toList(),
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
                        evaluateJavaScript(browserModel, value);
                      },
                      controller: _customJavaScriptController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                          hintText: "document.querySelector('body') ...",
                          prefixIcon: Icon(Icons.keyboard_arrow_right,
                              color: Colors.blue),
                          border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () {
                      evaluateJavaScript(
                          browserModel, _customJavaScriptController.text);
                    },
                  ),
                  Column(
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
                                  webViewModel.javaScriptConsoleHistory[
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
                                webViewModel.javaScriptConsoleHistory.length) {
                              currentJavaScriptHistory =
                                  webViewModel.javaScriptConsoleHistory.length;
                              _customJavaScriptController.text = "";
                            } else {
                              currentJavaScriptHistory++;
                              _customJavaScriptController.text =
                                  webViewModel.javaScriptConsoleHistory[
                                      currentJavaScriptHistory];
                            }
                          },
                        ),
                      )
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () {
                      setState(() {
                        webViewModel.javaScriptConsoleResults.clear();
                      });
                    },
                  )
                ],
              ),
            )
          ],
        );
      },
    );
  }

  void evaluateJavaScript(BrowserModel browserModel, String source) async {
    var webViewModel = browserModel.getCurrentTab().webViewModel;
    if (source.isNotEmpty &&
        (webViewModel.javaScriptConsoleHistory.length == 0 ||
            (webViewModel.javaScriptConsoleHistory.length > 0 &&
                webViewModel.javaScriptConsoleHistory.last != source))) {
      webViewModel.javaScriptConsoleHistory.add(source);
    }

    var result =
        await webViewModel.webViewController.evaluateJavascript(source: source);

    webViewModel.javaScriptConsoleResults.add(RichText(
      text: TextSpan(
        text: result.toString(),
        style: TextStyle(color: Colors.black),
      ),
    ));

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
    return LayoutBuilder(
        builder: (context, constraints) {
          return Consumer<BrowserModel>(builder: (context, browserModel, child) {
            var webViewModel = browserModel.getCurrentTab().webViewModel;

            var rows = <DataRow>[];

            var textStyle = TextStyle(fontSize: 14.0);

            rows.addAll(webViewModel.loadedResources.reversed.map((loadedResoruce) {
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

              return DataRow(cells: <DataCell>[
                DataCell(
                  Container(
                      width: constraints.maxWidth / 2.5,
                      child: Row(
                        children: <Widget>[
                          loadedResoruce.initiatorType == 'img'
                              ? CachedNetworkImage(
                            imageUrl: loadedResoruce.url,
                            width: 20.0,
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
                      )),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: loadedResoruce.url));
                  },
                ),
                DataCell(Container(
                  width: constraints.maxWidth / 5.5,
                  child:
                  Text(domain, overflow: TextOverflow.ellipsis, style: textStyle),
                )),
                DataCell(
                  Text(loadedResoruce.initiatorType, style: textStyle),
                ),
                DataCell(
                  Text(loadedResoruce.duration.toStringAsFixed(2) + " ms",
                      style: textStyle),
                )
              ]);
            }).toList());

            return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 200.0,
                      padding: EdgeInsets.only(left: 10.0),
                      child: charts.ScatterPlotChart(_createChartData(webViewModel.loadedResources),
                          animate: false,
                          behaviors: [
                            new charts.SlidingViewport(),
                            new charts.PanAndZoomBehavior(),
                          ],
                          defaultRenderer:
                          charts.PointRendererConfig(pointRendererDecorators: [
                            charts.ComparisonPointsDecorator(
                                symbolRenderer: charts.CylinderSymbolRenderer())
                          ])),
                    ),
                    Container(
                      width: constraints.minWidth,
                      child: DataTable(
                        columnSpacing: 5.0,
                        columns: const <DataColumn>[
                          DataColumn(
                            label: const Text(
                              "Name",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                            ),
                          ),
                          DataColumn(
                            label: const Text(
                              "Domain",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                            ),
                          ),
                          DataColumn(
                            label: const Text(
                              "Type",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                            ),
                          ),
                          DataColumn(
                            label: const Text(
                              "Time",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                            ),
                          ),
                        ],
                        rows: rows,
                      ),
                    ),
                  ],
                ));
          });
        }
    );
  }

  List<charts.Series> seriesList;

  /// Create one series with sample hard coded data.
  static List<charts.Series<LoadedResource, double>> _createChartData(List<LoadedResource> data) {
    return [
      new charts.Series<LoadedResource, double>(
        id: 'LoadedResource',
        // Providing a color function is optional.
        colorFn: (LoadedResource loadedResource, _) {
          return charts.Color(
            r: ((loadedResource.startTime + loadedResource.duration) * 0xFFFFFF).toInt(),
            b: (loadedResource.startTime * 0xFFFFFF).toInt(),
            g: (loadedResource.duration * 0xFFFFFF).toInt(),
          );
        },
        domainFn: (LoadedResource loadedResource, _) => loadedResource.startTime + loadedResource.duration,
        domainLowerBoundFn: (LoadedResource loadedResource, _) => loadedResource.startTime,
        domainUpperBoundFn: (LoadedResource loadedResource, _) => loadedResource.startTime + loadedResource.duration,
        measureFn: (LoadedResource loadedResource, _) => data.indexOf(loadedResource),
        measureLowerBoundFn: (LoadedResource loadedResource, _) => loadedResource.duration,
        measureUpperBoundFn: (LoadedResource loadedResource, _) => loadedResource.duration,
        radiusPxFn: (LoadedResource loadedResource, _) => 2,
        data: data,
      )
    ];
  }

  Widget _buildStorageTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Consumer<BrowserModel>(
            builder: (context, browserModel, child) {
              var webViewModel = browserModel.getCurrentTab().webViewModel;

              return FutureBuilder(
                future: _cookieManager.getCookies(url: webViewModel.url),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }

                  List<Cookie> cookies = snapshot.data;

                  var rows = <DataRow>[];
                  var textStyle = TextStyle(fontSize: 16.0);

                  rows.addAll(cookies.map((cookie) {
                    return DataRow(
                        cells: <DataCell>[
                          DataCell(
                            Container(
                            width: constraints.maxWidth / 3,
                              child: Text(cookie.name, style: textStyle, softWrap: true),
                            ),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: "${cookie.name}=${cookie.value}"));
                            },
                          ),
                          DataCell(
                            Container(
                              width: constraints.maxWidth / 3,
                              child: Text(cookie.value, style: textStyle, softWrap: true),
                            ),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: "${cookie.name}=${cookie.value}"));
                            },
                          ),
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.cancel),
                              onPressed: () {
                                setState(() {
                                  _cookieManager.deleteCookie(url: webViewModel.url, name: cookie.name);
                                });
                              },
                            )
                          )
                        ]
                    );
                  }).toList());

                  return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: <Widget>[
                          Center(
                            child: Container(
                              padding: EdgeInsets.only(top: 10.0),
                              child: const Text("Cookies", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
                            ),
                          ),
                          Divider(),
                          Container(
                            width: constraints.minWidth,
                            child: DataTable(
                              columnSpacing: 0.0,
                              columns: const <DataColumn>[
                                DataColumn(
                                  label: const Text(
                                    "Name",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                                  ),
                                ),
                                DataColumn(
                                  label: const Text(
                                    "Value",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                                  ),
                                ),
                                DataColumn(
                                  label: const Text(
                                    "Delete",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
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
                                  child: Text("Clear cookies"),
                                  onPressed: () {
                                    setState(() {
                                      _cookieManager.deleteCookies(url: webViewModel.url);
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
                      ));
                },
              );
            }
        );
      },
    );
  }
}
