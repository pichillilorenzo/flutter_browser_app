
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_browser/app_bar/certificates_info_popup.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:provider/provider.dart';

import '../custom_popup_dialog.dart';

class UrlInfoPopup extends StatefulWidget {
  final CustomPopupDialogPageRoute route;
  final Duration transitionDuration;
  final Function() onWebViewTabSettingsClicked;

  UrlInfoPopup({Key key, this.route, this.transitionDuration, this.onWebViewTabSettingsClicked}) : super(key: key);

  @override
  _UrlInfoPopupState createState() => _UrlInfoPopupState();
}

class _UrlInfoPopupState extends State<UrlInfoPopup> {
  var text1 = "Your connection to this website is not protected";
  var text2 = "You should not enter sensitive data on this site (e.g. passwords or credit cards) because they could be intercepted by malicious users.";

  var showFullInfoUrl = false;
  var defaultTextSpanStyle = TextStyle(
    color: Colors.black54,
    fontSize: 12.5,
  );

  @override
  Widget build(BuildContext context) {
    var webViewModel = Provider.of<WebViewModel>(context, listen: true);
    if (webViewModel.isSecure) {
      text1 = "Your connection is protected";
      text2 = "Your sensitive data (e.g. passwords or credit card numbers) remains private when it is sent to this site.";
    }
    var uri = Uri.parse(webViewModel.url);

    return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      showFullInfoUrl = !showFullInfoUrl;
                    });
                  },
                  child: Container(
                      padding: EdgeInsets.only(bottom: 15.0),
                      constraints: BoxConstraints(maxHeight: 100.0),
                      child: RichText(
                        maxLines: showFullInfoUrl ? null : 2,
                        overflow: showFullInfoUrl
                            ? TextOverflow.clip
                            : TextOverflow.ellipsis,
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                                text: uri.scheme,
                                style: defaultTextSpanStyle.copyWith(
                                  color:
                                  webViewModel.isSecure ? Colors.green : Colors.black54,
                                  fontWeight: FontWeight.bold
                                )),
                            TextSpan(text: webViewModel.url.trim() == "about:blank" ? ':' : '://', style: defaultTextSpanStyle),
                            TextSpan(
                                text: uri.host,
                                style: defaultTextSpanStyle.copyWith(
                                    color: Colors.black)),
                            TextSpan(
                                text: uri.path, style: defaultTextSpanStyle),
                            TextSpan(
                                text:
                                uri.query.isNotEmpty ? "?" + uri.query : "",
                                style: defaultTextSpanStyle),
                          ],
                        ),
                      )),
                );
              },
            ),
            Container(
              padding: EdgeInsets.only(bottom: 10.0),
              child: Text(text1,
                  style: TextStyle(
                    fontSize: 16.0,
                  )),
            ),
            Container(
              child: RichText(
                  text: TextSpan(
                      style: TextStyle(fontSize: 12.0, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: text2 + " ",
                        ),
                        TextSpan(
                          text: "Details",
                          style: TextStyle(color: Colors.blue),
                          recognizer: TapGestureRecognizer()..onTap = () async {

                            Navigator.maybePop(context);

                            await widget.route.popped;

                            await Future.delayed(Duration(milliseconds: widget.transitionDuration.inMilliseconds - 200));

                            showDialog(
                              context: context,
                              builder: (context) {
                                return CertificateInfoPopup();
                              },
                            );
                          },
                        ),
                      ]
                  )
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FlatButton(
                child: Text(
                  "WebView Tab Settings",
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                ),
                onPressed: () async {
                  Navigator.maybePop(context);

                  await widget.route.popped;

                  Future.delayed(widget.transitionDuration, () {
                    widget.onWebViewTabSettingsClicked();
                  });
                },
              ),
            ),
          ],
        ));
  }
  
}