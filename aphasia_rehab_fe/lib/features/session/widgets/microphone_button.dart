import 'package:flutter/material.dart';
import '../../../services/transcription_service.dart';

class MicrophoneButton extends StatefulWidget {
  final TranscriptionService service;
  final Function(bool isRecording)? onToggle;

  const MicrophoneButton({
    super.key,
    required this.service,
    this.onToggle,
  });

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton> {
  bool _isRecording = false;

  void _handleToggle() {
    bool starting = !_isRecording;

    if (_isRecording) {
      widget.service.stopStreaming();
    } else {
      widget.service.startStreaming();
    }

    setState(() => _isRecording = starting);

    // If a callback was provided, run it!
    if (widget.onToggle != null) {
      widget.onToggle!(starting);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'mic_btn',
      onPressed: _handleToggle,
      backgroundColor: _isRecording ? Colors.red : Colors.deepPurple,
      child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
    );
  }
}
