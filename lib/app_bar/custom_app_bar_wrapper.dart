import 'package:flutter/material.dart';
import 'package:flutter_browser/app_bar/desktop_app_bar.dart';
import 'package:flutter_browser/util.dart';

class CustomAppBarWrapper extends StatefulWidget implements PreferredSizeWidget {
  final AppBar appBar;

  CustomAppBarWrapper({super.key, required this.appBar})
      : preferredSize = Util.isMobile()
            ? _PreferredAppBarSize(
                kToolbarHeight, appBar.bottom?.preferredSize.height)
            : Size.fromHeight(_PreferredAppBarSize(
                        kToolbarHeight, appBar.bottom?.preferredSize.height)
                    .height +
                40);

  @override
  State<CustomAppBarWrapper> createState() => _CustomAppBarWrapperState();

  @override
  final Size preferredSize;
}

class _CustomAppBarWrapperState extends State<CustomAppBarWrapper> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    if (Util.isDesktop()) {
      children.add(const DesktopAppBar(showTabs: false,));
    } else {
      return widget.appBar;
    }

    children.add(Flexible(child: widget.appBar));

    return Column(
      children: children,
    );
  }
}

class _PreferredAppBarSize extends Size {
  _PreferredAppBarSize(this.toolbarHeight, this.bottomHeight)
      : super.fromHeight(
            (toolbarHeight ?? kToolbarHeight) + (bottomHeight ?? 0));

  final double? toolbarHeight;
  final double? bottomHeight;
}
