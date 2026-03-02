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
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (scenarioSimManager.hintButtonPressed)
          Positioned(
            bottom: 110,
            left: 0,
            child: SizedBox(height: 150, width: 300, child: SelectHint()),
          ),

        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20.0,
          children: [
            HintButton(),
            Column(
              spacing: 5.0,
              children: [
                ElevatedButton( //adding menu button
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
        ),
      ],
    );
  }
}
