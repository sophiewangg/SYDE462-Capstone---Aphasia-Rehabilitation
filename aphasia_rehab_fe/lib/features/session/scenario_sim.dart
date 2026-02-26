import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/speech_bubble.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/character.dart';
import 'widgets/settings_button.dart';

class ScenarioSim extends StatefulWidget {
  const ScenarioSim({super.key});

  @override
  State<ScenarioSim> createState() => _ScenarioSimState();
}

class _ScenarioSimState extends State<ScenarioSim> {
  @override
  void initState() {
    super.initState();
    // Request permissions right when the screen loads
    Future.microtask(() {
      if (mounted) {
        context.read<ScenarioSimManager>().requestMicPermission();
      }
    });
  }

  // Note: We don't need a dispose() method here anymore because the
  // ScenarioSimManager handles all the cleanup for streams and audio!

  @override
  Widget build(BuildContext context) {
    // Watch the manager so the UI updates when text or state changes
    final manager = context.watch<ScenarioSimManager>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  "assets/backgrounds/restaurant_background.png",
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Custom Back Button
          Positioned(
            top: 75,
            left: 20,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 32,
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  manager.stopRecording(); // Stop mic before leaving
                  Navigator.pop(context);
                },
              ),
            ),
          ),

          // Settings Button
          const Positioned(top: 75, right: 20, child: SettingsButton()),

          // Character Image
          const Positioned(bottom: 30, right: 0, child: Character()),

          // Table Foreground Image
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/table_image.png',
              height: 250,
              fit: BoxFit.contain,
            ),
          ),

          // Main Interaction UI (Speech Bubble & Buttons)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: SizedBox(
                width: 350,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10.0,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Uses the manager's currentPrompt
                    SpeechBubble(prompt: manager.currentPrompt),

                    // System Message (e.g., "I didn't quite catch that")
                    SizedBox(
                      height: 46,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: (manager.systemMessage == null)
                            ? const SizedBox.shrink()
                            : Text(
                                manager.systemMessage!,
                                key: const ValueKey("system_message"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                ),
                                softWrap: true,
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // The combined Mic and Hint button row
                    // (This widget already handles SelectHint and Mic logic internally!)
                    const MicAndHintButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
