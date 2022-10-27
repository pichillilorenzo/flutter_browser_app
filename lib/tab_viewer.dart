import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'main.dart';

class ScrollableTab extends StatefulWidget {
  final Widget child;
  final double top;
  final Function? onTap;

  const ScrollableTab(
      {Key? key, required this.child, this.top = 0.0, this.onTap})
      : super(key: key);

  @override
  State<ScrollableTab> createState() => _ScrollableTabState();
}

class _ScrollableTabState extends State<ScrollableTab> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          }
        },
        child: Transform.scale(
          scale: 0.95,
          child: Column(
            children: <Widget>[
              Expanded(
                child: widget.child,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class TabViewer extends StatefulWidget {
  final List<Widget> children;
  final int currentIndex;
  final Function(int index)? onTap;

  const TabViewer(
      {Key? key, required this.children, this.onTap, this.currentIndex = 0})
      : super(key: key);

  @override
  State<TabViewer> createState() => _TabViewerState();
}

class _TabViewerState extends State<TabViewer>
    with SingleTickerProviderStateMixin {
  List<double> positions = [];
  int focusedIndex = 0;
  bool initialized = false;
  Timer? _timer;
  double decelerationRate = 1.5;

  @override
  void initState() {
    super.initState();
    positions = List.filled(widget.children.length, 0.0, growable: true);

    focusedIndex = widget.currentIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      initialize();
    }
  }

  void initialize() {
    for (var i = 0; i < widget.children.length; i++) {
      if (widget.currentIndex == i) {
        if (widget.currentIndex == 0) {
          positions[widget.currentIndex] = TAB_VIEWER_TOP_OFFSET_1;
        } else if (widget.currentIndex == 1) {
          positions[widget.currentIndex] = TAB_VIEWER_TOP_OFFSET_2;
        } else if (widget.currentIndex >= 2) {
          positions[widget.currentIndex] = TAB_VIEWER_TOP_OFFSET_3;
        }
      } else {
        if (i < widget.currentIndex) {
          if (i == 0) {
            positions[i] = TAB_VIEWER_TOP_OFFSET_1;
          } else if (i == 1) {
            positions[i] = TAB_VIEWER_TOP_OFFSET_2;
          } else if (i >= 2) {
            positions[i] = TAB_VIEWER_TOP_OFFSET_3;
          }
        } else {
          if (i == positions.length - 1) {
            positions[i] =
                MediaQuery.of(context).size.height - TAB_VIEWER_BOTTOM_OFFSET_1;
          } else if (i == positions.length - 2) {
            positions[i] =
                MediaQuery.of(context).size.height - TAB_VIEWER_BOTTOM_OFFSET_2;
          } else if (i <= positions.length - 3) {
            positions[i] =
                MediaQuery.of(context).size.height - TAB_VIEWER_BOTTOM_OFFSET_3;
          }
        }
      }
    }
  }

  @override
  void didUpdateWidget(TabViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    var diffLength = oldWidget.children.length - widget.children.length;
    if (diffLength > 0) {
      _timer?.cancel();
      positions.removeRange(
          positions.length - diffLength - 1, positions.length - 1);
      focusedIndex = focusedIndex - 1 < 0 ? 0 : focusedIndex - 1;
      if (positions.length == 1) {
        positions[0] = TAB_VIEWER_TOP_OFFSET_1;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _timer?.cancel();
              updatePositions(details.delta.dy);
            });
          },
          onVerticalDragEnd: (details) {
            var dy = details.velocity.pixelsPerSecond.dy / (1000 / 16);
            var deceleration = dy > 0 ? -decelerationRate : decelerationRate;

            _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
              if (positions.isEmpty ||
                  (deceleration < 0 && dy <= 0) ||
                  (deceleration >= 0 && dy >= 0)) {
                _timer?.cancel();
                return;
              }

              setState(() {
                updatePositions(dy);
              });
              dy = dy + deceleration;
            });
          },
          child: Stack(
            children: widget.children.map((tab) {
              var index = widget.children.indexOf(tab);
              var opacity = 0.2;
              if (index == focusedIndex &&
                  index != 0 &&
                  index != positions.length - 1) {
                opacity = 0.15;
              } else if ((index > 2 &&
                      positions[index] <= TAB_VIEWER_TOP_OFFSET_3) ||
                  (index < positions.length - 3 &&
                      positions[index] >=
                          MediaQuery.of(context).size.height -
                              TAB_VIEWER_BOTTOM_OFFSET_3)) {
                opacity = 0.0;
              }

              double scale = 1.0;
              if (positions[index] < TAB_VIEWER_TOP_SCALE_TOP_OFFSET) {
                scale =
                    (positions[index] / TAB_VIEWER_TOP_SCALE_TOP_OFFSET) + 0.85;
                if (scale > 1) {
                  scale = 1.0;
                }
              } else if (positions[index] >
                  MediaQuery.of(context).size.height -
                      TAB_VIEWER_TOP_SCALE_BOTTOM_OFFSET) {
                var diff = MediaQuery.of(context).size.height -
                    TAB_VIEWER_BOTTOM_OFFSET_1 -
                    positions[index];
                scale = (diff / TAB_VIEWER_TOP_SCALE_BOTTOM_OFFSET) + 0.7;
                if (scale > 1) {
                  scale = 1.0;
                }
              } else {
                scale = 1.0;
              }

              return ScrollableTab(
                onTap: () {
                  if (widget.onTap != null) {
                    widget.onTap!(index);
                  }
                },
                top: positions[index],
                child: Transform(
                  transform: Matrix4.identity()..scale(scale, scale),
                  alignment: Alignment.topCenter,
                  child: Container(
                      decoration: BoxDecoration(boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(opacity),
                          spreadRadius: 5,
                          blurRadius: 5,
                        ),
                      ]),
                      child: tab),
                ),
              );
            }).toList(),
          )),
    );
  }

  void updatePositions(double dy) {
    positions[focusedIndex] =
        focusedIndex != 0 ? positions[focusedIndex] + dy : 0.0;
    if (focusedIndex == 0 &&
        positions[focusedIndex] <= TAB_VIEWER_TOP_OFFSET_1) {
      positions[focusedIndex] = TAB_VIEWER_TOP_OFFSET_1;
      focusedIndex = min(positions.length - 1, focusedIndex);
    } else if (focusedIndex == 1 &&
        positions[focusedIndex] < TAB_VIEWER_TOP_OFFSET_2) {
      positions[focusedIndex] = TAB_VIEWER_TOP_OFFSET_2;
      focusedIndex = min(positions.length - 1, focusedIndex + 1);
    } else if (focusedIndex >= 2 &&
        positions[focusedIndex] < TAB_VIEWER_TOP_OFFSET_3) {
      positions[focusedIndex] = TAB_VIEWER_TOP_OFFSET_3;
      focusedIndex = min(positions.length - 1, focusedIndex + 1);
    } else if (focusedIndex == positions.length - 1 &&
        positions[focusedIndex] >
            MediaQuery.of(context).size.height - TAB_VIEWER_BOTTOM_OFFSET_1) {
      positions[focusedIndex] =
          MediaQuery.of(context).size.height - TAB_VIEWER_BOTTOM_OFFSET_1;
      focusedIndex = max(0, focusedIndex - 1);
    } else if (focusedIndex == positions.length - 2 &&
        positions[focusedIndex] >
            MediaQuery.of(context).size.height - TAB_VIEWER_BOTTOM_OFFSET_2) {
      positions[focusedIndex] =
          MediaQuery.of(context).size.height - TAB_VIEWER_BOTTOM_OFFSET_2;
      focusedIndex = max(0, focusedIndex - 1);
    } else if (focusedIndex <= positions.length - 3 &&
        positions[focusedIndex] >
            MediaQuery.of(context).size.height - TAB_VIEWER_BOTTOM_OFFSET_3) {
      positions[focusedIndex] =
          MediaQuery.of(context).size.height - TAB_VIEWER_BOTTOM_OFFSET_3;
      focusedIndex = max(0, focusedIndex - 1);
    }
    if (focusedIndex == 0 &&
        dy < 0 &&
        positions.isNotEmpty &&
        focusedIndex + 1 < positions.length) {
      focusedIndex++;
      positions[focusedIndex] = positions[focusedIndex] + dy;
    }

    if (focusedIndex == 0) {
      _timer?.cancel();
    } else if (focusedIndex == positions.length - 1 &&
        positions[focusedIndex] <= TAB_VIEWER_TOP_OFFSET_3) {
      _timer?.cancel();
    } else if (focusedIndex == positions.length - 2 &&
        positions.length == 2 &&
        positions[focusedIndex] <= TAB_VIEWER_TOP_OFFSET_2) {
      _timer?.cancel();
    }
  }
}
