import 'package:flutter/material.dart';
import '../../../services/transcription_service.dart';

class TranscriptionDisplay extends StatelessWidget {
  final Stream<TranscriptionResult> stream;

  const TranscriptionDisplay({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TranscriptionResult>(
      stream: stream,
      builder: (context, snapshot) {
        String displayText = "Press start to transcribe...";
        double? confidence;

        if (snapshot.hasData) {
          final data = snapshot.data!;
          // Only update display text if we have actual text
          if (data.text.isNotEmpty) {
            displayText = data.text;
          }
          confidence = data.confidence;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (confidence != null)
                Text(
                  "Confidence: ${(confidence * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 10),
              Text(
                displayText,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
