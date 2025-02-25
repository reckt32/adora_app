import 'package:flutter/material.dart';

// reusable button for starting/stopping tracking
class TrackingButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onToggle;
  
  // constructor takes current state and callback
  const TrackingButton({
    Key? key,
    required this.isRunning,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onToggle,
      icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
      label: Text(isRunning ? 'Stop Tracking' : 'Start Tracking'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isRunning ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}