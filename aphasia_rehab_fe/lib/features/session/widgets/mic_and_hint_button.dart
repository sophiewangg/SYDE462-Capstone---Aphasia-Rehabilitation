import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/hint_button.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_idle.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_processing.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_speaking.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/select_hint.dart';
import 'package:flutter/material.dart';
import 'package:aphasia_rehab_fe/models/microphone_state.dart';
import 'package:provider/provider.dart';

class MicAndHintButton extends StatefulWidget {
  const MicAndHintButton({super.key});

  @override
  State<MicAndHintButton> createState() => _MicAndHintButtonState();
}

class _MicAndHintButtonState extends State<MicAndHintButton> {
  Widget _buildMicButton(ScenarioSimManager manager) {
    // Access the state directly from the manager we pass in
    switch (manager.currentMicrophoneState) {
      case MicrophoneState.idle:
        return MicButtonIdle();
      case MicrophoneState.userSpeaking:
        return MicButtonSpeaking();
      case MicrophoneState.processing:
        return MicButtonProcessing();
      default:
        return MicButtonIdle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transcriptionManager = context.watch<ScenarioSimManager>();
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10.0,
      children: [
        SizedBox(
          height: 150,
          child: scenarioSimManager.hintButtonPressed
              ? SelectHint()
              : const SizedBox.shrink(),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20.0,
          children: [HintButton(), _buildMicButton(transcriptionManager)],
        ),
      ],
    );
  }
}
