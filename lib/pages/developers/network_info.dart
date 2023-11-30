// import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/custom_image.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
// import 'package:charts_flutter/flutter.dart' as charts;

class NetworkInfo extends StatefulWidget {
  const NetworkInfo({super.key});

  @override
  State<NetworkInfo> createState() => _NetworkInfoState();
}

class _NetworkInfoState extends State<NetworkInfo> {
  @override
  Widget build(BuildContext context) {
    return _buildNetworkInfo();
  }

  Widget _buildNetworkInfo() {
    return LayoutBuilder(builder: (context, constraints) {
      return Selector<WebViewModel, List<LoadedResource>>(
          selector: (context, webViewModel) => webViewModel.loadedResources,
          builder: (context, loadedResources, child) {
            var textStyle = const TextStyle(fontSize: 14.0);

            var listViewChildren = <Widget>[
              // Container(
              //   height: 200.0,
              //   padding: EdgeInsets.only(left: 10.0),
              //   child: charts.ScatterPlotChart(
              //       _createChartData(loadedResources),
              //       animate: false,
              //       behaviors: [
              //         charts.SlidingViewport(),
              //         charts.PanAndZoomBehavior(),
              //       ],
              //       defaultRenderer:
              //           charts.PointRendererConfig(pointRendererDecorators: [
              //         charts.ComparisonPointsDecorator(
              //             symbolRenderer: charts.CylinderSymbolRenderer())
              //       ])),
              // ),
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
              var url = loadedResoruce.url ?? Uri.parse("about:blank");
              String path = url.path;
              String resourceName = path.substring(path.lastIndexOf('/') + 1);

              String domain = url.host.replaceFirst("www.", "");

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

              Widget icon;
              var mimeType = lookupMimeType(url.toString());

              if (mimeType != null &&
                  mimeType.startsWith("image/") &&
                  mimeType != "image/svg+xml") {
                // icon = CachedNetworkImage(
                //   imageUrl: url.toString(),
                //   width: 20.0,
                //   height: 20.0,
                //   errorWidget: (context, url, error) {
                //     return Icon(
                //       Icons.broken_image,
                //       size: 20.0,
                //     );
                //   },
                // );
                icon = CustomImage(url: url, maxWidth: 20.0, height: 20.0);
              } else if (mimeType == "image/svg+xml") {
                icon = SvgPicture.network(
                  url.toString(),
                  width: 20.0,
                  height: 20.0,
                );
              } else {
                icon = Icon(
                  iconData,
                  size: 20.0,
                );
              }

              return Row(children: <Widget>[
                InkWell(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: loadedResoruce.url?.toString() ?? ''));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 2.5),
                      width: constraints.maxWidth / 3.0,
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: icon,
                          ),
                          const SizedBox(
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
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 2.5),
                  child: Text(domain,
                      overflow: TextOverflow.ellipsis, style: textStyle),
                ),
                Container(
                  width: constraints.maxWidth / 4,
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 2.5),
                  alignment: Alignment.center,
                  child: Text(loadedResoruce.initiatorType ?? "",
                      style: textStyle),
                ),
                Flexible(
                    child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 2.5),
                  child: Text(
                      (loadedResoruce.duration != null)
                          ? "${loadedResoruce.duration!.toStringAsFixed(2)} ms"
                          : "",
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

  // List<charts.Series> seriesList;
  //
  // /// Create one series with sample hard coded data.
  // static List<charts.Series<LoadedResource, double>> _createChartData(
  //     List<LoadedResource> data) {
  //   return [
  //     new charts.Series<LoadedResource, double>(
  //       id: 'LoadedResource',
  //       // Providing a color function is optional.
  //       colorFn: (LoadedResource loadedResource, _) {
  //         return charts.Color(
  //           r: ((loadedResource.startTime + loadedResource.duration) * 0xFFFFFF)
  //               .toInt(),
  //           b: (loadedResource.startTime * 0xFFFFFF).toInt(),
  //           g: (loadedResource.duration * 0xFFFFFF).toInt(),
  //         );
  //       },
  //       domainFn: (LoadedResource loadedResource, _) =>
  //           loadedResource.startTime + loadedResource.duration,
  //       domainLowerBoundFn: (LoadedResource loadedResource, _) =>
  //           loadedResource.startTime,
  //       domainUpperBoundFn: (LoadedResource loadedResource, _) =>
  //           loadedResource.startTime + loadedResource.duration,
  //       measureFn: (LoadedResource loadedResource, _) =>
  //           data.indexOf(loadedResource),
  //       measureLowerBoundFn: (LoadedResource loadedResource, _) =>
  //           loadedResource.duration,
  //       measureUpperBoundFn: (LoadedResource loadedResource, _) =>
  //           loadedResource.duration,
  //       radiusPxFn: (LoadedResource loadedResource, _) => 2,
  //       data: data,
  //     )
  //   ];
  // }
}
