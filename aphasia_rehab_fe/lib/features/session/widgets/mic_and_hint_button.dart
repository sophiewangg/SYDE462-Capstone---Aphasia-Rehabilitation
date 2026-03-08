import 'package:aphasia_rehab_fe/features/session/managers/hint_manager.dart';
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
    }
  }

  Widget _buildButtonRow(ScenarioSimManager scenarioSimManager) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20.0,
      children: [
        HintButton(),
        Column(
          spacing: 5.0,
          children: [
            ElevatedButton(
              onPressed: scenarioSimManager.toggleBobEateryModal,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                fixedSize: const Size(72, 72),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Icon(Icons.restaurant),
            ),
            Text("Menu", style: TextStyle(color: Colors.white)),
          ],
        ),
        _buildMicButton(scenarioSimManager),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();
    final hintManager = context.watch<HintManager>();
    final showSelectHint = hintManager.hintButtonPressed;

    // Use Column when hint is shown so SelectHint stays within hit-test bounds
    // (Stack+Positioned caused overflow; taps were going to SpeechBubble behind)
    if (showSelectHint) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 300, child: SelectHint()),
          const SizedBox(height: 10),
          _buildButtonRow(scenarioSimManager),
        ],
      );
    }

    return _buildButtonRow(scenarioSimManager);
  }
}
