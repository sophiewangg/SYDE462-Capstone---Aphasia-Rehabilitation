import 'package:flutter/material.dart';
import '../../../models/cue_model.dart';
// Removed transcription_service import
// Removed microphone_button import

class CueModal extends StatefulWidget {
  final Future<Cue?> cueFuture;
  // Removed transcriptionService

  const CueModal({
    super.key,
    required this.cueFuture,
    // Removed transcriptionService
  });

  @override
  State<CueModal> createState() => _CueModalState();
}

class _CueModalState extends State<CueModal> {
  int _cuesUsed = 0;
  bool _cueComplete = false;

  String _getHintText(int stage, Cue fetchedCue) {
    switch (stage) {
      case 0:
        return "Meaning: ${fetchedCue.semantic}";
      case 1:
        return "Rhymes with: ${fetchedCue.rhyming}";
      case 2:
        return "Starts with: ${fetchedCue.firstSound.toUpperCase()}";
      default:
        return "Try the word: ${fetchedCue.likelyWord}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cue?>(
      future: widget.cueFuture,
      builder: (context, cueSnapshot) {
        if (cueSnapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 300, // Reduced height since mic is gone
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            ),
          );
        }

        if (cueSnapshot.hasError || !cueSnapshot.hasData) {
          return const Center(child: Text("Error loading hints."));
        }

        final fetchedCue = cueSnapshot.data!;

        // Removed StreamBuilder since we don't need real-time transcription here anymore

        return Container(
          width: double.infinity,
          height: 300, // Reduced height
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min size for a "popup/notification" feel
            children: [
              const Text(
                'Need a Hint?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                _getHintText(_cuesUsed, fetchedCue),
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Removed MicrophoneButton

              const SizedBox(height: 20),

              _cueComplete
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Return to exercise',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _cuesUsed++;
                              if (_cuesUsed >= 3) _cueComplete = true;
                            });
                          },
                          child: const Text('Another hint please!'),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                           onPressed: () => Navigator.pop(context),
                           child: const Text("Cancel"),
                        )
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}
