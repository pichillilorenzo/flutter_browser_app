import 'package:flutter/material.dart';

class AccessibilityFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const AccessibilityFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: const CircleAvatar(
        backgroundColor: Colors.blue, // Change the color as needed
        child: Icon(
          Icons.accessibility,
          color: Colors.white, // Change the icon color as needed
        ),
      ),
    );
  }
}

class MovableAccessibilityFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const MovableAccessibilityFAB({super.key, required this.onPressed});

  @override
  // ignore: library_private_types_in_public_api
  _MovableAccessibilityFABState createState() =>
      _MovableAccessibilityFABState();
}

class _MovableAccessibilityFABState extends State<MovableAccessibilityFAB> {
  double fabX = 100.0; // Initial X position
  double fabY = 100.0; // Initial Y position

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 0, // Align to the right edge of the screen
          bottom: 0, // Align to the bottom edge of the screen
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                fabX += details.delta.dx;
                fabY += details.delta.dy;
              });
            },
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: Colors.transparent, // Make it transparent
              child: const CircleAvatar(
                backgroundColor: Colors.blue, // Change the color as needed
                child: Icon(
                  Icons.accessibility,
                  color: Colors.white, // Change the icon color as needed
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
