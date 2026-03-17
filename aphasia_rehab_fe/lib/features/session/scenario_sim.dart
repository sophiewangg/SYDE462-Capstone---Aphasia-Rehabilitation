import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/dashboard/dashboard_page.dart';
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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: dialogueBottom,
            child: SpeechBubble(),
          ),
          if (scenarioSimManager.showRaiseHandButton)
            Positioned(
              left: 0,
              right: 0,
              bottom: dialogueBottom + 100,
              child: Center(child: RaiseHandButton(onPressed: () {})),
            ),

          // ═══════════════════════════════════════════════════════════════
          // LAYER 3: HUD — controls (hint, menu, speak, settings)
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
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(top: 75, right: 20, child: SettingsButton()),
          Positioned(
            top: 150,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                scenarioSimManager.handleEndOfSession();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardPage(),
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
              children: [MicAndHintButton()],
            ),
          ),
        ],
      ),
    );
  }
}
