import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button_cue_modal.dart';
import 'package:aphasia_rehab_fe/models/prompt_state.dart';
import 'package:flutter/material.dart';
import '../../../models/cue_model.dart';
// Removed transcription_service import
// Removed microphone_button import

class CueModal extends StatefulWidget {
  final Future<Cue?> cueFuture;
  final Function() startRecording;
  final Function() updateCurrentPromptState;
  final PromptState currentPromptState;

  const CueModal({
    super.key,
    required this.cueFuture,
    required this.startRecording,
    required this.updateCurrentPromptState,
    required this.currentPromptState,
  });

  @override
  State<CueModal> createState() => _CueModalState();
}

class _CueModalState extends State<CueModal> {
  int _cuesUsed = 0;
  bool _cueComplete = false;
  final ValueNotifier<PromptState> _currentPromptState = ValueNotifier(
    PromptState.idle,
  );

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

  void updateCurrentPromptState() {
    if (_currentPromptState.value == PromptState.userSpeaking) {
      _currentPromptState.value = PromptState.processing;
      processSpeechResult();
    } else if (_currentPromptState.value == PromptState.idle) {
      _currentPromptState.value = PromptState.userSpeaking;
    }
  }

  void processSpeechResult() async {
    print("Processing speech result");
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
            decoration: BoxDecoration(
              color: _cueComplete
                  ? AppColors.cueModalComplete
                  : AppColors.cueModalInProgress,
              borderRadius: BorderRadius.circular(32.0),
            ),
            child: const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          );
        }

        if (cueSnapshot.hasError || !cueSnapshot.hasData) {
          return const Center(child: Text("Error loading hints."));
        }

        final fetchedCue = cueSnapshot.data!;

        return Container(
          width: double.infinity,
          height: 325, // Reduced height
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cueModalInProgress,
            borderRadius: BorderRadius.circular(32.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize
                .min, // Use min size for a "popup/notification" feel
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    side: BorderSide.none,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 350,
                padding: const EdgeInsets.all(8.0), // Adds space inside the box
                decoration: BoxDecoration(
                  color: AppColors.hintBackground, // The hint background color
                  borderRadius: BorderRadius.circular(
                    8.0,
                  ), // Optional: rounds the corners
                ),
                child: Text(
                  _getHintText(_cuesUsed, fetchedCue),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ), // Ensure text is visible on white
                  textAlign: TextAlign.start,
                ),
              ),

              // Removed MicrophoneButton
              const SizedBox(height: 40),

              MicAndHintButtonCueModal(
                startRecording: widget.startRecording,
                updateCurrentPromptState: widget.updateCurrentPromptState,
                currentPromptState: widget.currentPromptState,
              ),

              // _cueComplete
              //     ? ElevatedButton(
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: Colors.green,
              //         ),
              //         onPressed: () => Navigator.pop(context),
              //         child: const Text(
              //           'Return to exercise',
              //           style: TextStyle(color: Colors.white),
              //         ),
              //       )
              //     : Column(
              //         children: [
              //           ElevatedButton(
              //             onPressed: () {
              //               setState(() {
              //                 _cuesUsed++;
              //                 if (_cuesUsed >= 3) _cueComplete = true;
              //               });
              //             },
              //             child: const Text('Another hint please!'),
              //           ),
              //           const SizedBox(height: 10),
              //         ],
              //       ),
            ],
          ),
        );
      },
    );
  }
}
