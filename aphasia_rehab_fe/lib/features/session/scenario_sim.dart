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
  bool _isBobEateryModalOpen = false;

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

  void _toggleBobEateryModal() {
    setState(() {
      _isBobEateryModalOpen = !_isBobEateryModalOpen;
    });
  }

  // Note: We don't need a dispose() method here anymore because the
  // ScenarioSimManager handles all the cleanup for streams and audio!

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 2 / 3;
    // Place the dialogue roughly where the menu button column starts
    final dialogueBaseBottom = screenHeight * 0.33;
    final scenarioSimManager = context.watch<ScenarioSimManager>();
    // Calculate menu button position: 12px above MicAndHintButton
    // MicAndHintButton height: 72px (Row) + optionally 150px (SelectHint) when hint pressed
    final micAndHintButtonHeight = scenarioSimManager.hintButtonPressed ? 222.0 : 72.0;
    final menuButtonBottom = 30.0 + micAndHintButtonHeight + 12.0;

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
                        padding:
                            const EdgeInsets.fromLTRB(24, 24 + 40, 24, 120),
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
                                style: TextStyle(
                                  fontSize: 14,
                                ),
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
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Entrées box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.black, width: 1),
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
                                      "Grilled steak cooked to your liking, served\nwith roasted potatoes and vegetables.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
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
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
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
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
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
            bottom:
                _isBobEateryModalOpen ? modalHeight + 16 : dialogueBaseBottom,
            child: const SpeechBubble(prompt: manager.currentPrompt),
          ),
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

