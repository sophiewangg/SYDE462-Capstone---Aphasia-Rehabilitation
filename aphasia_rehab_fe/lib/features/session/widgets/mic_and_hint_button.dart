import 'package:aphasia_rehab_fe/features/session/widgets/hint_button.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_idle.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_processing.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_speaking.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/select_hint.dart';
import 'package:flutter/material.dart';
import 'package:aphasia_rehab_fe/models/prompt_state.dart';

class MicAndHintButton extends StatefulWidget {
  final String currentPrompt;
  final bool hintButtonPressed;
  final PromptState currentPromptState;
  final Function() updateCurrentPromptState;
  final Function() toggleHintButton;
  final Function() onPressedMic;
  final Function() handleHintPressed;

  const MicAndHintButton({
    super.key,
    required this.currentPrompt,
    required this.hintButtonPressed,
    required this.currentPromptState,
    required this.updateCurrentPromptState,
    required this.toggleHintButton,
    required this.onPressedMic,
    required this.handleHintPressed,
  });

  @override
  State<MicAndHintButton> createState() => _MicAndHintButtonState();
}

class _MicAndHintButtonState extends State<MicAndHintButton> {
  Widget _buildMicButton() {
    switch (widget.currentPromptState) {
      case PromptState.idle:
        return MicButtonIdle(
          updateCurrentPromptState: widget.updateCurrentPromptState,
          onPressedMic: widget.onPressedMic,
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
          onPressedMic: widget.onPressedMic,
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
        SizedBox(
          height: 150,
          child: widget.hintButtonPressed
              ? SelectHint(handleHintPressed: widget.handleHintPressed)
              : const SizedBox.shrink(),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20.0,
          children: [
            HintButton(
              toggleHintButton: widget.toggleHintButton,
              hintButtonPressed: widget.hintButtonPressed,
            ),
            _buildMicButton(),
          ],
        ),
      ],
    );
  }
}
