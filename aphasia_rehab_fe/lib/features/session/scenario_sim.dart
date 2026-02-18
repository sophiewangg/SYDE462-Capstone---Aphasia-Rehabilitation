import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/select_hint.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/speech_bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'widgets/settings_button.dart';
import 'widgets/character.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:aphasia_rehab_fe/models/prompt_state.dart';

class ScenarioSim extends StatefulWidget {
  const ScenarioSim({super.key});

  @override
  State<ScenarioSim> createState() => _ScenarioSimState();
}

class _ScenarioSimState extends State<ScenarioSim> {
  final _player = AudioPlayer();
  bool _hintButtonPressed = false;
  List<String> prompts = [
    "Hello! How are you doing?",
    "Would you like something to drink?",
    "What would you like to order?",
    "Here is your food. Enjoy your meal!",
    "Can I get you anything else?",
    "Thank you! Have a great day!",
  ];
  int _currentPromptIndex = 0;
  PromptState _currentPromptState = PromptState.idle;

  void toggleHintButton() {
    setState(() {
      _hintButtonPressed = !_hintButtonPressed;
    });
  }

  void updateCurrentPromptState() {
    if (_currentPromptState == PromptState.userSpeaking) {
      setState(() {
        _currentPromptState = PromptState.processing;
      });

      // Simulate processing delay
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentPromptIndex =
                (_currentPromptIndex + 1) % prompts.length; // Loop prompts
            _currentPromptState = PromptState.idle;
          });
          startPromptTimer();
        }
      });
    } else if (_currentPromptState == PromptState.idle) {
      setState(() {
        _currentPromptState = PromptState.userSpeaking;
      });
    }
  }

  void startPromptTimer() async {
    await _player.play(AssetSource('audio_clips/server_speech_1.mp3'));

    // .first ensures we don't keep listening after it finishes
    await _player.onPlayerComplete.first;

    if (mounted) {
      setState(() {
        _currentPromptState = PromptState.userSpeaking;
      });
    }
  }

  // Trigger it when the screen first loads
  @override
  void initState() {
    super.initState();
    startPromptTimer();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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

          Positioned(bottom: 30, right: 0, child: Character()),
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/table_image.png',
              height: 250,
              fit: BoxFit.contain,
            ),
          ),

          Positioned(top: 75, right: 20, child: SettingsButton()),

          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10.0,
              children: [
                SpeechBubble(prompt: prompts[_currentPromptIndex]),
                const SizedBox(height: 20),

                // MicAndHintButton(
                //   currentPrompt: prompts[_currentPromptIndex],
                //   hintButtonPressed: _hintButtonPressed,
                //   currentPromptState: _currentPromptState,
                //   updateCurrentPromptState: updateCurrentPromptState,
                //   toggleHintButton: toggleHintButton,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
