import 'package:flutter/material.dart';
import '../../../models/cue_model.dart';
import '../../../services/transcription_service.dart';
import 'microphone_button.dart';

class CueModal extends StatefulWidget {
  final Future<Cue?> cueFuture;
  final TranscriptionService transcriptionService;

  const CueModal({
    super.key,
    required this.cueFuture,
    required this.transcriptionService,
  });

  @override
  State<CueModal> createState() => _CueModalState();
}

class _CueModalState extends State<CueModal> {
  int _cuesUsed = 0;
  bool _cueComplete = false;
  String _latestSpeech = ""; // Local variable to track what was said

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
            height: 400,
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: SizedBox(
                width: 40, // Fixed width
                height: 40, // Fixed height
                child: CircularProgressIndicator(
                  strokeWidth: 3, // Makes the line a bit thinner/cleaner
                ),
              ),
            ),
          );
        }

        if (cueSnapshot.hasError || !cueSnapshot.hasData) {
          return const Center(child: Text("Error loading hints."));
        }

        final fetchedCue = cueSnapshot.data!;

        return StreamBuilder<String>(
          stream: widget.transcriptionService.transcriptionStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _latestSpeech = snapshot.data!;
            }

            return Container(
              width: double.infinity,
              height: 400,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Need a Hint?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _getHintText(_cuesUsed, fetchedCue),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Spacer(),

                  MicrophoneButton(
                    service: widget.transcriptionService,
                    onToggle: (isNowRecording) {
                      if (!isNowRecording) {
                        // Compare against the LIVE speech captured during this modal session
                        if (_latestSpeech.toLowerCase().contains(
                          fetchedCue.likelyWord.toLowerCase(),
                        )) {
                          setState(() {
                            _cueComplete = true;
                          });
                        }
                      }
                    },
                  ),

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
                      : ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _cuesUsed++;
                              if (_cuesUsed >= 3) _cueComplete = true;
                            });
                          },
                          child: const Text('Another hint please!'),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
