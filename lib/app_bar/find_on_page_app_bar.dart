import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:provider/provider.dart';
import '../InputDoneView.dart';

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

class FindOnPageAppBar extends StatefulWidget {
  final void Function()? hideFindOnPage;

  const FindOnPageAppBar({Key? key, this.hideFindOnPage}) : super(key: key);

  @override
  State<FindOnPageAppBar> createState() => _FindOnPageAppBarState();
}

class _FindOnPageAppBarState extends State<FindOnPageAppBar> {
  final TextEditingController _finOnPageController = TextEditingController();
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

  OutlineInputBorder outlineBorder = const OutlineInputBorder(
    borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    borderRadius: BorderRadius.all(
      Radius.circular(50.0),
    ),
  );

  @override
  void dispose() {
    numberFocusNode.dispose();
    _finOnPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var findInteractionController = webViewModel?.findInteractionController;

    return AppBar(
      titleSpacing: 10.0,
      title: SizedBox(
          height: 40.0,
          child: TextField(
            focusNode: numberFocusNode,
            onSubmitted: (value) {
              findInteractionController?.findAll(find: value);
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
              hintStyle: const TextStyle(color: Colors.black54, fontSize: 16.0),
            ),
            style: const TextStyle(color: Colors.black, fontSize: 16.0),
          )),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          onPressed: () {
            findInteractionController?.findNext(forward: false);
          },
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () {
            findInteractionController?.findNext(forward: true);
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            findInteractionController?.clearMatches();
            _finOnPageController.text = "";

            if (widget.hideFindOnPage != null) {
              widget.hideFindOnPage!();
            }
          },
        ),
      ],
    );
  }
}
