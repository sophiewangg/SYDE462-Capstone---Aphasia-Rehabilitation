import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/hint_button_cue_modal.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_idle.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_processing.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_button_speaking.dart';
import 'package:flutter/material.dart';
import 'package:aphasia_rehab_fe/models/microphone_state.dart';
import 'package:provider/provider.dart';

class MicAndHintButtonCueModal extends StatefulWidget {
  const MicAndHintButtonCueModal({super.key});

  @override
  State<MicAndHintButtonCueModal> createState() =>
      _MicAndHintButtonCueModalState();
}

class _MicAndHintButtonCueModalState extends State<MicAndHintButtonCueModal> {
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
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10.0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20.0,
          children: [
            HintButtonCueModal(),
            _buildMicButton(scenarioSimManager),
          ],
        ),
      ],
    );
  }
}
