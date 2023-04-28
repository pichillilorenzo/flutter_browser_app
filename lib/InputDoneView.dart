import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io' show Platform;
import 'qr_scan_page.dart';

class InputDoneView extends StatefulWidget {
  const InputDoneView({super.key});

  @override
  State<InputDoneView> createState() => _InputDoneViewState();
}

class _InputDoneViewState extends State<InputDoneView> {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: ElevatedButton.icon(
                icon: Icon(Icons.qr_code_scanner),
                onPressed: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const QRCode(),
                  ));
                },
                label: const Text("Scan",
                    style: TextStyle(
                      color: Colors.white,
                    )),
              ),
            )));
  }
}
