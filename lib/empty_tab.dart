import 'package:flutter/material.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'InputDoneView.dart';
import 'models/browser_model.dart';
import 'models/webview_model.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class KeyboardOverlay {
  static OverlayEntry? _overlayEntry;

  static showOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      return;
    }

    OverlayState? overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          right: 0.0,
          left: 0.0,
          child: const InputDoneView());
    });

    overlayState.insert(_overlayEntry!);
  }

  static removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}

class EmptyTab extends StatefulWidget {
  const EmptyTab({Key? key}) : super(key: key);

  @override
  State<EmptyTab> createState() => _EmptyTabState();
}

class _EmptyTabState extends State<EmptyTab> {
  final _controller = TextEditingController();
  FocusNode numberFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    numberFocusNode.addListener(() {
      bool hasFocus = numberFocusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    // Clean up the focus node
    numberFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage(settings.searchEngine.assetIcon)),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    child: TextField(
                  focusNode: numberFocusNode,
                  controller: _controller,
                  onSubmitted: (value) {
                    openNewTab(value);
                  },
                  textInputAction: TextInputAction.go,
                  decoration: const InputDecoration(
                    hintText: "Search for or type a web address",
                    hintStyle: TextStyle(color: Colors.black54, fontSize: 25.0),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 25.0,
                  ),
                )),
                IconButton(
                  icon: const Icon(Icons.search,
                      color: Colors.black54, size: 25.0),
                  onPressed: () {
                    openNewTab(_controller.text);
                    FocusScope.of(context).unfocus();
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void openNewTab(value) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    browserModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel: WebViewModel(
          url: WebUri(value.startsWith("http")
              ? value
              : settings.searchEngine.searchUrl + value)),
    ));
  }
}
