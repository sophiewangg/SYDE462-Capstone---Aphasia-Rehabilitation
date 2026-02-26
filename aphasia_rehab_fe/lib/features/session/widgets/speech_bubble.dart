import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'play_audio_button.dart';

class SpeechBubble extends StatefulWidget {
  const SpeechBubble({super.key});

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble> {
  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 350,
        child: Stack(
          clipBehavior: Clip.none, // Required to let the tip sit on the border
          children: [
            // 1. The main Speech Bubble
            Container(
              // The margin creates space ABOVE the bubble for the tip to exist
              margin: const EdgeInsets.only(top: 20),
              width: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 12.0,
                ),
                child: Row(
                  spacing: 12.0,
                  children: [
                    SizedBox(width: 40, height: 40, child: PlayAudioButton()),
                    Expanded(
                      child: Text(
                        scenarioSimManager.currentPrompt,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. The Tip (Positioned on the top border)
            Positioned(
              top: -80, // Adjust this to move speech bubble tip higher
              left: 30,
              child: Image.asset(
                'assets/images/speech_bubble_tip_image.png',
                width: 150,
              ),
            ),
            SizedBox(
              height: 46,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: (scenarioSimManager.systemMessage == null)
                    ? const SizedBox.shrink()
                    : Text(
                        scenarioSimManager.systemMessage!,
                        key: const ValueKey("system_message"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                        softWrap: true,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
