import 'package:aphasia_rehab_fe/features/session/widgets/raise_hand_button.dart';
import 'package:flutter/material.dart';

class WaitScenarioOverlay extends StatelessWidget {
  final bool showTimer;
  final int simulatedMinutes;
  final bool showMessage;
  final VoidCallback onRaiseHand;

  const WaitScenarioOverlay({
    super.key,
    required this.showTimer,
    required this.simulatedMinutes,
    required this.showMessage,
    required this.onRaiseHand,
  });

  @override
  Widget build(BuildContext context) {
    // If neither should show, render nothing
    if (!showTimer && !showMessage) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 60.0, left: 24.0, right: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- STATE 1: THE TIMER BADGE ---
            if (showTimer)
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
                      '$simulatedMinutes mins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // --- STATE 2: THE MESSAGE & YOUR CUSTOM BUTTON ---
            if (showMessage) ...[
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

              // Your custom widget!
              RaiseHandButton(onPressed: onRaiseHand),
            ],
          ],
        ),
      ),
    );
  }
}
