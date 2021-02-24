import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomImage extends StatelessWidget {
  final double? width;
  final double? height;
  final double maxWidth;
  final double maxHeight;
  final double minWidth;
  final double minHeight;
  final Uri? url;

  CustomImage({Key? key, this.url, this.width, this.height,
    this.maxWidth = double.infinity, this.maxHeight = double.infinity,
    this.minWidth = 0.0, this.minHeight = 0.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: this.maxWidth,
        maxHeight: this.maxHeight,
        minHeight: this.minHeight,
        minWidth: this.minWidth
      ),
      width: this.width,
      height: this.height,
      child: getImage(),
    );

  }

  Widget? getImage() {
    if (url != null) {
      if (url!.scheme == "data") {
        Uint8List bytes = Base64Decoder().convert(url.toString().replaceFirst("data:image/png;base64,", ""));
        return Image.memory(bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => getBrokenImageIcon(),);
      }
      return Image.network(url.toString(),
          fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => getBrokenImageIcon(),);
    }
    return getBrokenImageIcon();
  }

  Widget getBrokenImageIcon() {
    return Icon(
      Icons.broken_image,
      size: this.width ?? this.height ?? this.maxWidth,
    );
  }
}