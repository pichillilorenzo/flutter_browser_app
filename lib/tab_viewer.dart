import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class ScrollableTab extends StatefulWidget {
  final Widget child;
  final double top;
  final Function onTap;

  ScrollableTab(
      {Key key,
      this.child,
      this.top = 0.0,
      this.onTap})
      : super(key: key);

  @override
  _ScrollableTabState createState() => _ScrollableTabState();
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
          widget.onTap();
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
  final Function(int index) onTap;

  TabViewer({Key key, this.children, this.onTap, this.currentIndex = 0})
      : super(key: key);

  @override
  _TabViewerState createState() => _TabViewerState();
}

class _TabViewerState extends State<TabViewer> with SingleTickerProviderStateMixin {
  List<double> positions = [];
  int focusedIndex = 0;
  bool initialized = false;
  Timer _timer;
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
          positions[widget.currentIndex] = 0;
        } else if (widget.currentIndex == 1) {
          positions[widget.currentIndex] = 10;
        } else if (widget.currentIndex >= 2) {
          positions[widget.currentIndex] = 20;
        }
      } else {
        if (i < widget.currentIndex) {
          if (i == 0) {
            positions[i] = 0;
          } else if (i == 1) {
            positions[i] = 10;
          } else if (i >= 2) {
            positions[i] = 20;
          }
        } else {
          if (i == positions.length - 1) {
            positions[i] = MediaQuery.of(context).size.height - 120;
          } else if (i == positions.length - 2) {
            positions[i] = MediaQuery.of(context).size.height - 130;
          } else if (i <= positions.length - 3) {
            positions[i] = MediaQuery.of(context).size.height - 140;
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
      positions.removeRange(positions.length - diffLength - 1, positions.length - 1);
      focusedIndex--;
      if (positions.length == 1) {
        positions[0] = 0.0;
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
        body: SafeArea(
      child: GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _timer?.cancel();
              updatePositions(details.delta.dy);
            });
          },
          onVerticalDragEnd: (details) {
            var dy = details.velocity.pixelsPerSecond.dy / (1000 / 16);
            var deceleration = dy > 0 ? -decelerationRate : decelerationRate;

            _timer = Timer.periodic(new Duration(milliseconds: 16), (timer) {
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
              } else if ((index > 2 && positions[index] <= 20) ||
                  (index < positions.length - 3 &&
                      positions[index] >=
                          MediaQuery.of(context).size.height - 140)) {
                opacity = 0.0;
              }

              double scale = 1.0;
              if (positions[index] < 250) {
                scale = (positions[index] / 250) + 0.85;
                if (scale > 1) {
                  scale = 1.0;
                }
              }
              else if (positions[index] > MediaQuery.of(context).size.height - 230) {
                var diff = MediaQuery.of(context).size.height - 120 - positions[index];
                scale = (diff / 230) + 0.7;
                if (scale > 1) {
                  scale = 1.0;
                }
              }
              else {
                scale = 1.0;
              }

              return ScrollableTab(
                  onTap: () {
                    widget.onTap(index);
                  },
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
                  top: positions[index],
                );
            }).toList(),
          )),
    ));
  }

  void updatePositions(double dy) {
    positions[focusedIndex] =
        focusedIndex != 0 ? positions[focusedIndex] + dy : 0.0;
    if (focusedIndex == 0 && positions[focusedIndex] <= 0) {
      positions[focusedIndex] = 0;
      focusedIndex = min(positions.length - 1, focusedIndex + 1);
    } else if (focusedIndex == 1 && positions[focusedIndex] < 10) {
      positions[focusedIndex] = 10;
      focusedIndex = min(positions.length - 1, focusedIndex + 1);
    } else if (focusedIndex >= 2 && positions[focusedIndex] < 20) {
      positions[focusedIndex] = 20;
      focusedIndex = min(positions.length - 1, focusedIndex + 1);
    } else if (focusedIndex == positions.length - 1 &&
        positions[focusedIndex] > MediaQuery.of(context).size.height - 120) {
      positions[focusedIndex] = MediaQuery.of(context).size.height - 120;
      focusedIndex = max(0, focusedIndex - 1);
    } else if (focusedIndex == positions.length - 2 &&
        positions[focusedIndex] > MediaQuery.of(context).size.height - 130) {
      positions[focusedIndex] = MediaQuery.of(context).size.height - 130;
      focusedIndex = max(0, focusedIndex - 1);
    } else if (focusedIndex <= positions.length - 3 &&
        positions[focusedIndex] > MediaQuery.of(context).size.height - 140) {
      positions[focusedIndex] = MediaQuery.of(context).size.height - 140;
      focusedIndex = max(0, focusedIndex - 1);
    }
    if (focusedIndex == 0 && dy < 0 && positions.length > 0 && focusedIndex + 1 < positions.length) {
      focusedIndex++;
      positions[focusedIndex] = positions[focusedIndex] + dy;
    }
  }
}
