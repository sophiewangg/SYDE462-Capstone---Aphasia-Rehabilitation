import 'package:flutter/material.dart';

class MicrophoneButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const MicrophoneButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'mic_btn',
      onPressed: onPressed,
      backgroundColor: isRecording ? Colors.red : Colors.deepPurple,
      child: Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.white),
    );
  }
}
