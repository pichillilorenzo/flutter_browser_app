import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:provider/provider.dart';

class FindOnPageAppBar extends StatefulWidget {
  final void Function() hideFindOnPage;

  FindOnPageAppBar({Key key, this.hideFindOnPage}): super(key: key);

  @override
  _FindOnPageAppBarState createState() => _FindOnPageAppBarState();
}

class _FindOnPageAppBarState extends State<FindOnPageAppBar> {

  TextEditingController _finOnPageController = TextEditingController();

  OutlineInputBorder outlineBorder = OutlineInputBorder(
    borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    borderRadius: const BorderRadius.all(
      const Radius.circular(50.0),
    ),
  );

  @override
  void dispose() {
    _finOnPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var _webViewController = webViewModel?.webViewController;

    return AppBar(
      titleSpacing: 10.0,
      title: Container(
          height: 40.0,
          child: TextField(
            onSubmitted: (value) {
              _webViewController?.findAllAsync(find: value);
            },
            controller: _finOnPageController,
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(10.0),
              filled: true,
              fillColor: Colors.white,
              border: outlineBorder,
              focusedBorder: outlineBorder,
              enabledBorder: outlineBorder,
              hintText: "Find on page ...",
              hintStyle: TextStyle(color: Colors.black54, fontSize: 16.0),
            ),
            style: TextStyle(color: Colors.black, fontSize: 16.0),
          )),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.keyboard_arrow_up),
          onPressed: () {
            _webViewController?.findNext(forward: false);
          },
        ),
        IconButton(
          icon: Icon(Icons.keyboard_arrow_down),
          onPressed: () {
            _webViewController?.findNext(forward: true);
          },
        ),
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            _webViewController?.clearMatches();
            _finOnPageController.text = "";

            widget?.hideFindOnPage();
          },
        ),
      ],
    );
  }

}