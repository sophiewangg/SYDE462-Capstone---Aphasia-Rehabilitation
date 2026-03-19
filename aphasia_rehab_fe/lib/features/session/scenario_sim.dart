import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/food.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/menu.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/receipt.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/static_receipt.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/raise_hand_button.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/speech_bubble.dart';
import 'package:aphasia_rehab_fe/services/session_dashboard_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/settings_button.dart';
import 'widgets/character.dart';
import 'dart:async';

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
    final receiptHeight = screenHeight * 2 / 3;
    final dialogueBaseBottom = screenHeight * 0.34;
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    // Dialogue sits above menu or receipt when either is open, else at base position.
    final dialogueBottom = scenarioSimManager.isBobEateryModalOpen
        ? modalHeight + 16
        : scenarioSimManager.showReceiptSheet ||
              scenarioSimManager.showStaticReceiptSheet
        ? receiptHeight + 16
        : dialogueBaseBottom;

    return Scaffold(
      body: Stack(
        children: [
          // ═══════════════════════════════════════════════════════════════
          // LAYER 1: BACKGROUND — scene content (painted first, at the back)
          // ═══════════════════════════════════════════════════════════════
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

          if (!scenarioSimManager.showWaitTimer &&
              !scenarioSimManager.showSystemMessage)
            Positioned(bottom: 30, right: 0, child: Character()),
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/table_image.png',
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
          if (scenarioSimManager.appetizerUrl != null &&
              scenarioSimManager.showAppetizer.contains(
                scenarioSimManager.currentStep,
              ))
            Positioned(
              bottom: screenHeight * 0.18,
              right: 200,
              child: Food(foodUrl: scenarioSimManager.appetizerUrl!),
            ),
          if (scenarioSimManager.entreeUrl != null &&
              scenarioSimManager.showEntree.contains(
                scenarioSimManager.currentStep,
              ))
            Positioned(
              bottom: screenHeight * 0.18,
              right: 20,
              child: Food(foodUrl: scenarioSimManager.entreeUrl!),
            ),

          // ═══════════════════════════════════════════════════════════════
          // LAYER 2: IN-BETWEEN — display sheets (menu, receipt, server dialogue)
          // ═══════════════════════════════════════════════════════════════
          Menu(modalHeight: modalHeight),
          Receipt(receiptHeight: receiptHeight),
          StaticReceipt(receiptHeight: receiptHeight),
          if (!scenarioSimManager.showWaitTimer &&
              !scenarioSimManager.showSystemMessage)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: dialogueBottom,
              child: SpeechBubble(),
            ),
          // ═══════════════════════════════════════════════════════════════
          // LAYER 3: HUD — controls (hint, menu, speak, settings, wait UI)
          // ═══════════════════════════════════════════════════════════════
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
                  scenarioSimManager.handleEndOfSession();
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
              spacing: 10.0,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [MicAndHintButton()],
            ),
          ),

          // --- LONG WAIT SCENARIO UI ---
          if (scenarioSimManager.showWaitTimer ||
              scenarioSimManager.showSystemMessage)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 400.0,
                  left: 24.0,
                  right: 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The Timer Badge
                    if (scenarioSimManager.showWaitTimer)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${scenarioSimManager.simulatedWaitMinutes} mins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // The System Message & Button
                    if (scenarioSimManager.showSystemMessage) ...[
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Your food is taking a while... try getting the server's attention.",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Your custom hand raise button
                      // Your custom hand raise button
                      if (scenarioSimManager.showRaiseHandButton)
                        RaiseHandButton(
                          onPressed: () {
                            // Safely grab the configuration from the context
                            final config = createLocalImageConfiguration(
                              context,
                            );
                            scenarioSimManager.raiseHandPressed(config);
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
