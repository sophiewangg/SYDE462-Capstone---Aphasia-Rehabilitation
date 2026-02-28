import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/menu.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/speech_bubble.dart';
import 'package:aphasia_rehab_fe/services/session_dashboard_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/settings_button.dart';
import 'widgets/character.dart';
import 'dart:async';
import 'package:aphasia_rehab_fe/features/session/session_dashboard_page.dart';

class ScenarioSim extends StatefulWidget {
  const ScenarioSim({super.key});

  @override
  State<ScenarioSim> createState() => _ScenarioSimState();
}

class _ScenarioSimState extends State<ScenarioSim> {
  final SessionDashboardService _dashboardService = SessionDashboardService();

  @override
  void initState() {
    super.initState();

    _dashboardService.clearDetections();

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
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 2 / 3;
    // Place the dialogue roughly where the menu button column starts
    final dialogueBaseBottom = screenHeight * 0.33;
    final scenarioSimManager = context.watch<ScenarioSimManager>();

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
          Menu(modalHeight: modalHeight),
          // App dialogue that slides with the Bob's Eatery modal
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: scenarioSimManager.isBobEateryModalOpen
                ? modalHeight + 16
                : dialogueBaseBottom,
            child: SpeechBubble(),
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
            top: 150,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                scenarioSimManager.stopRecording();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SessionDashboardPage(),
                  ),
                );
              },
              child: const Text('End Session'),
            ),
          ),

          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              spacing: 10.0,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                MicAndHintButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
