import 'package:aphasia_rehab_fe/features/session/widgets/hint_button.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/hint_button_cue_modal.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_idle.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_processing.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_speaking.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/select_hint.dart';
import 'package:flutter/material.dart';
import 'package:aphasia_rehab_fe/models/prompt_state.dart';

class MicAndHintButtonCueModal extends StatefulWidget {
  final PromptState currentPromptState;
  final Function() startRecording;
  final Function() updateCurrentPromptState;
  final Function() updateCueNumber;

  const MicAndHintButtonCueModal({
    super.key,
    required this.startRecording,
    // required this.currentPrompt,
    // required this.hintButtonPressed,
    required this.currentPromptState,
    required this.updateCurrentPromptState,
    // required this.toggleHintButton,
    // required this.onPressedMic,
    // required this.handleHintPressed,
    required this.updateCueNumber,
  });

  @override
  State<MicAndHintButtonCueModal> createState() =>
      _MicAndHintButtonCueModalState();
}

class _MicAndHintButtonCueModalState extends State<MicAndHintButtonCueModal> {
  Widget _buildMicButton() {
    switch (widget.currentPromptState) {
      case PromptState.idle:
        return MicButtonIdle(
          updateCurrentPromptState: widget.updateCurrentPromptState,
          onPressedMic: widget.startRecording,
        );
      case PromptState.userSpeaking:
        return MicButtonSpeaking(
          updateCurrentPromptState: widget.updateCurrentPromptState,
        );
      case PromptState.processing:
        return MicButtonProcessing();
      default:
        return MicButtonIdle(
          updateCurrentPromptState: widget.updateCurrentPromptState,
          onPressedMic: widget.startRecording,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10.0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20.0,
          children: [HintButtonCueModal(updateCueNumber: widget.updateCueNumber), _buildMicButton()],
        ),
      ],
    );
  }
}
