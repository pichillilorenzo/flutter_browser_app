import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JavaScriptConsoleResult extends StatefulWidget {
  final String data;
  final Color textColor;
  final Color backgroundColor;
  final IconData? iconData;
  final Color? iconColor;

  const JavaScriptConsoleResult(
      {Key? key,
      this.data = "",
      this.textColor = Colors.black,
      this.backgroundColor = Colors.transparent,
      this.iconData,
      this.iconColor})
      : super(key: key);

  @override
  State<JavaScriptConsoleResult> createState() =>
      _JavaScriptConsoleResultState();
}

class _JavaScriptConsoleResultState extends State<JavaScriptConsoleResult> {
  @override
  Widget build(BuildContext context) {
    var textSpanChildrens = <InlineSpan>[];
    if (widget.iconData != null) {
      textSpanChildrens.add(WidgetSpan(
        child: Container(
          padding: const EdgeInsets.only(right: 5.0),
          child: Icon(widget.iconData, color: widget.iconColor, size: 14),
        ),
        alignment: PlaceholderAlignment.middle,
      ));
    }
    textSpanChildrens.add(TextSpan(
      text: widget.data,
      style: TextStyle(color: widget.textColor),
    ));

    return Material(
      color: widget.backgroundColor,
      child: InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.data));
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            color: Colors.transparent,
            child: RichText(
              text: TextSpan(
                children: textSpanChildrens,
              ),
            ),
          )),
    );
  }
}
