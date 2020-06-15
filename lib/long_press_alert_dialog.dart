import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import 'models/browser_model.dart';
import 'models/webview_model.dart';

class LongPressAlertDialog extends StatefulWidget {
  static const List<InAppWebViewHitTestResultType> HIT_TEST_RESULT_SUPPORTED = [
    InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE,
    InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE,
    InAppWebViewHitTestResultType.IMAGE_TYPE
  ];

  LongPressAlertDialog({Key key, this.webViewModel, this.hitTestResult, this.requestFocusNodeHrefResult})
      : super(key: key);

  final WebViewModel webViewModel;
  final InAppWebViewHitTestResult hitTestResult;
  final RequestFocusNodeHrefResult requestFocusNodeHrefResult;

  @override
  _LongPressAlertDialogState createState() => _LongPressAlertDialogState();
}

class _LongPressAlertDialogState extends State<LongPressAlertDialog> {
  var _isLinkPreviewReady = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      content: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildDialogLongPressHitTestResult(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDialogLongPressHitTestResult() {
    if (widget.hitTestResult.type ==
            InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE ||
        widget.hitTestResult.type ==
            InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE || (
        widget.hitTestResult.type ==
            InAppWebViewHitTestResultType.IMAGE_TYPE && widget.requestFocusNodeHrefResult != null
            && widget.requestFocusNodeHrefResult.url != null
    )) {
      return <Widget>[
        _buildLinkTile(),
        Divider(),
        _buildLinkPreview(),
        Divider(),
        _buildOpenNewTab(),
        _buildOpenNewIncognitoTab(),
        _buildCopyAddressLink(),
        _buildShareLink(),
      ];
    } else if (widget.hitTestResult.type ==
        InAppWebViewHitTestResultType.IMAGE_TYPE) {
      return <Widget>[
        _buildImageTile(),
        Divider(),
        _buildOpenImageNewTab(),
        _buildDownloadImage(),
        _buildSearchImageOnGoogle(),
        _buildShareImage(),
      ];
    }

    return [];
  }

  Widget _buildLinkTile() {
    var uri = Uri.parse(widget.requestFocusNodeHrefResult.url);
    var faviconUrl = uri.origin + "/favicon.ico";

    var title = widget.requestFocusNodeHrefResult.title ?? "";
    if (title.isEmpty) {
      title = "Link";
    }

    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CachedNetworkImage(
            placeholder: (context, url) => CircularProgressIndicator(),
            imageUrl: widget.requestFocusNodeHrefResult.src != null ? widget.requestFocusNodeHrefResult.src : faviconUrl,
            height: 30,
          )
        ],
      ),
      title: Text(title),
      subtitle: Text(
        widget.requestFocusNodeHrefResult.url,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
    );
  }

  Widget _buildLinkPreview() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    return ListTile(
      title: Center(child: const Text("Link Preview")),
      subtitle: Container(
        padding: EdgeInsets.only(top: 15.0),
        height: 250,
        child: IndexedStack(
          index: _isLinkPreviewReady ? 1 : 0,
          children: <Widget>[
            Center(
              child: CircularProgressIndicator(),
            ),
            InAppWebView(
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                new Factory<OneSequenceGestureRecognizer>(
                  () => new EagerGestureRecognizer(),
                ),
              ].toSet(),
              initialUrl: widget.requestFocusNodeHrefResult.url,
              initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                debuggingEnabled: settings.debuggingEnabled,
              )),
              onProgressChanged: (controller, progress) {
                if (progress > 50) {
                  setState(() {
                    _isLinkPreviewReady = true;
                  });
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOpenNewTab() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    return ListTile(
      title: const Text("Open in a new tab"),
      onTap: () {
        browserModel.addTab(WebViewTab(
          key: GlobalKey(),
          webViewModel: WebViewModel(url: widget.hitTestResult.extra),
        ));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildOpenNewIncognitoTab() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    return ListTile(
      title: const Text("Open in a new incognito tab"),
      onTap: () {
        browserModel.addTab(WebViewTab(
          key: GlobalKey(),
          webViewModel: WebViewModel(
              url: widget.hitTestResult.extra, isIncognitoMode: true),
        ));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCopyAddressLink() {
    return ListTile(
      title: const Text("Copy address link"),
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.hitTestResult.extra));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildShareLink() {
    return ListTile(
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Share link"),
        Padding(
          padding: EdgeInsets.only(right: 12.5),
          child: Icon(
            Icons.share,
            color: Colors.black54,
            size: 20.0,
          ),
        )
      ]),
      onTap: () {
        Share.share(widget.hitTestResult.extra);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildImageTile() {
    return ListTile(
      contentPadding:
          EdgeInsets.only(left: 15.0, top: 15.0, right: 15.0, bottom: 5.0),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CachedNetworkImage(
            placeholder: (context, url) => CircularProgressIndicator(),
            imageUrl: widget.hitTestResult.extra,
            height: 50,
          ),
        ],
      ),
      title: Text(widget.webViewModel.title),
    );
  }

  Widget _buildDownloadImage() {
    return ListTile(
      title: const Text("Download image"),
      onTap: () async {
        var uri = Uri.parse(widget.hitTestResult.extra);
        String path = uri.path;
        String fileName = path.substring(path.lastIndexOf('/') + 1);

        final taskId = await FlutterDownloader.enqueue(
          url: widget.hitTestResult.extra,
          fileName: fileName,
          savedDir: (await getExternalStorageDirectory()).path,
          showNotification: true,
          openFileFromNotification: true,
        );
        Navigator.pop(context);
      },
    );
  }

  Widget _buildShareImage() {
    return ListTile(
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Share image"),
        Padding(
          padding: EdgeInsets.only(right: 12.5),
          child: Icon(
            Icons.share,
            color: Colors.black54,
            size: 20.0,
          ),
        )
      ]),
      onTap: () {
        Share.share(widget.hitTestResult.extra);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildOpenImageNewTab() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    return ListTile(
      title: const Text("Image in a new tab"),
      onTap: () {
        browserModel.addTab(WebViewTab(
          key: GlobalKey(),
          webViewModel: WebViewModel(url: widget.hitTestResult.extra),
        ));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSearchImageOnGoogle() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    return ListTile(
      title: const Text("Search this image on Google"),
      onTap: () {
        var url = "http://images.google.com/searchbyimage?image_url=" +
            widget.hitTestResult.extra;
        browserModel.addTab(WebViewTab(
          key: GlobalKey(),
          webViewModel: WebViewModel(url: url),
        ));
        Navigator.pop(context);
      },
    );
  }
}
