import 'dart:async';
import 'package:flutter/material.dart';

class OnlineIndicator extends StatefulWidget {
  final bool isOnline;
  final double size;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
  });

  @override
  State<OnlineIndicator> createState() => _OnlineIndicatorState();
}

class _OnlineIndicatorState extends State<OnlineIndicator> {
  int secondsOffline = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    if (!widget.isOnline) {
      startTimer();
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        secondsOffline++;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),

        if (!widget.isOnline)
          Text(
            '${secondsOffline}s ago',
            style: const TextStyle(fontSize: 10),
          ),
      ],
    );
  }
}
