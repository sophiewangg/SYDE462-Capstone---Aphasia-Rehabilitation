import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/speech_bubble.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/settings_button.dart';
import 'widgets/character.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class ScenarioSim extends StatefulWidget {
  const ScenarioSim({super.key});

  @override
  State<ScenarioSim> createState() => _ScenarioSimState();
}

class _ScenarioSimState extends State<ScenarioSim> {
  @override
  void initState() {
    super.initState();

    // Use context.read here because we only want to trigger the action once,
    // not "watch" for updates during the init phase.
    Future.microtask(() {
      if (mounted) {
        context.read<ScenarioSimManager>().requestMicPermission();
      }
    });
  }

  @override
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
          Positioned(
            top: 75,
            left: 20,
            child: Container(
              width: 64, // Total width of the circle
              height: 64, // Total height of the circle
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero, // Centers the icon perfectly
                iconSize: 32, // Size of the actual arrow icon
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
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
                SpeechBubble(),
                const SizedBox(height: 20),
                MicAndHintButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
