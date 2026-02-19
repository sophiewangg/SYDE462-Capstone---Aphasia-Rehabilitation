import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button_cue_modal.dart';
import 'package:aphasia_rehab_fe/models/prompt_state.dart';
import 'package:flutter/material.dart';
import '../../../models/cue_model.dart';

class CueModal extends StatefulWidget {
  final Future<Cue?> cueFuture;
  final Function() startRecording;
  final Function() updateCurrentPromptState;
  final PromptState currentPromptState;
  final bool cueComplete;
  final String? cueResultString;
  final int cueNumber;
  final Function({bool reset}) updateCueNumber;
  final Function() resetCueComplete;
  final Function() resetCueResultString;

  const CueModal({
    super.key,
    required this.cueFuture,
    required this.startRecording,
    required this.updateCurrentPromptState,
    required this.currentPromptState,
    required this.cueComplete,
    this.cueResultString,
    required this.cueNumber,
    required this.updateCueNumber,
    required this.resetCueComplete,
    required this.resetCueResultString,
  });

  @override
  State<CueModal> createState() => _CueModalState();
}

class _CueModalState extends State<CueModal> {
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
        return "Try the word: ${fetchedCue.likelyWord.toUpperCase()}";
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
              color: AppColors.cueModalInProgress,
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
          height: 350, // Reduced height
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.cueComplete
                ? AppColors.cueModalComplete
                : AppColors.cueModalInProgress,
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
                  onPressed: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 300));
                    widget.updateCueNumber(reset: true);
                    widget.resetCueComplete();
                    widget.resetCueResultString();
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
              widget.cueResultString != null
                  ? SizedBox(
                      child: Container(
                        width: 375,
                        padding: const EdgeInsets.all(
                          8.0,
                        ), // Adds space inside the box
                        decoration: BoxDecoration(
                          color: AppColors
                              .hintBackground, // The hint background color
                          borderRadius: BorderRadius.circular(
                            8.0,
                          ), // Optional: rounds the corners
                        ),
                        child: Text(
                          widget.cueResultString!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ), // Ensure text is visible on white
                          textAlign: TextAlign.start,
                        ),
                      ),
                    )
                  : SizedBox(height: 25),
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
                  _getHintText(widget.cueNumber, fetchedCue),
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
                updateCueNumber: widget.updateCueNumber,
              ),
            ],
          ),
        );
      },
    );
  }
}
