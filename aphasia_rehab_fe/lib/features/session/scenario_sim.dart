import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
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
  bool _isBobEateryModalOpen = false;

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

  void _toggleBobEateryModal() {
    setState(() {
      _isBobEateryModalOpen = !_isBobEateryModalOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 2 / 3;
    // Place the dialogue roughly where the menu button column starts
    final dialogueBaseBottom = screenHeight * 0.33;
    final scenarioSimManager = context.watch<ScenarioSimManager>();
    // Calculate menu button position: 12px above MicAndHintButton
    // MicAndHintButton height: 72px (Row) + optionally 150px (SelectHint) when hint pressed
    final micAndHintButtonHeight = scenarioSimManager.hintButtonPressed
        ? 222.0
        : 72.0;
    final menuButtonBottom = 30.0 + micAndHintButtonHeight + 12.0;

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
          // Bob's Eatery slide-up modal, rendered behind MicAndHintButton
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: _isBobEateryModalOpen ? 0 : -modalHeight,
            child: IgnorePointer(
              ignoring: !_isBobEateryModalOpen,
              child: Container(
                height: modalHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Stack(
                    children: [
                      // Scrollable menu content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          24 + 40,
                          24,
                          120,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: Text(
                                  "Bob's Eatery",
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontFamily: 'Lily Script One',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Starters
                              const Text(
                                "Bruschetta · 12",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Toasted bread topped with fresh tomatoes,\ngarlic, basil, and olive oil.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "Soup of the day · 10",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Chef's seasonal soup, served warm with\ntoasted bread. Ask the server for today's soup.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),

                              const SizedBox(height: 32),

                              // Entrées box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: const [
                                    Center(
                                      child: Text(
                                        "ENTRÉES",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Ribeye Steak · 34",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Grilled steak cooked to your liking, served\nwith a side of either fries or salad.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      "Seafood Alfredo · 24",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Fettuccine in creamy Alfredo sauce with\nshrimp and mixed seafood.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      "Chicken Katsu · 22",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Crispy breaded chicken cutlet served with\nrice and katsu sauce.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Drinks and Alcohol columns
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  // Drinks
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "DRINKS",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text("Soda · 4"),
                                      Text("Lemonade · 4.50"),
                                      Text("Tea · 4.50"),
                                      Text("Coffee · 4"),
                                    ],
                                  ),
                                  // Alcohol
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ALCOHOL",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text("Beer · 6"),
                                      Text("Wine · 100g · 7"),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Fixed circular close button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                            color: Colors.black87,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: _toggleBobEateryModal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // App dialogue that slides with the Bob's Eatery modal
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: _isBobEateryModalOpen
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

          // Menu button positioned on the left side, 12px above MicAndHintButton
          if (!_isBobEateryModalOpen)
            Positioned(
              bottom: 150,
              left: 30,
              child: ElevatedButton(
                onPressed: _toggleBobEateryModal,
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
            ),
          Positioned(bottom: 30, right: 20, child: MicAndHintButton()),
        ],
      ),
    );
  }
}
