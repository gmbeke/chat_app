import 'package:flutter/material.dart';

class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineIndicator({super.key, required this.isOnline, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
