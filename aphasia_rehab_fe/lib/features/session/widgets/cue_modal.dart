import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button_cue_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/cue_model.dart';

class CueModal extends StatefulWidget {
  final Future<Cue?> cueFuture;

  const CueModal({super.key, required this.cueFuture});

  @override
  State<CueModal> createState() => _CueModalState();
}

class _CueModalState extends State<CueModal> {
  bool _autoCloseScheduled = false;

  String _getHintText(int stage, Cue? fetchedCue) {
    if (fetchedCue == null) {
      return "Try saying \"I didn't understand that\"";
    }

    switch (stage) {
      case 0:
        return "Meaning: ${fetchedCue.semantic}";
      case 1:
        return "Rhymes with: ${fetchedCue.rhyming}";
      case 2:
        return "Starts with: ${fetchedCue.firstSound.toUpperCase()}";
      default:
        return "Try the word: ${fetchedCue.likelyWord.toUpperCase()}";
    }
  }

  void _scheduleAutoClose(BuildContext context, ScenarioSimManager scenarioSimManager) {
    if (_autoCloseScheduled) return;
    _autoCloseScheduled = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 300), () {
        scenarioSimManager.updateCueNumber(reset: true);
        scenarioSimManager.resetCueComplete();
        scenarioSimManager.resetCueResultString();
        scenarioSimManager.setIsModalOpen(false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    // Trigger auto-close when the modal turns green
    if (scenarioSimManager.cueCompleteNotifier.value) {
      _scheduleAutoClose(context, scenarioSimManager);
    }

    return FutureBuilder<Cue?>(
      future: widget.cueFuture,
      builder: (context, cueSnapshot) {
        // 1. Loading State
        if (cueSnapshot.connectionState == ConnectionState.waiting) {
          return _buildBaseContainer(
            scenarioSimManager: scenarioSimManager,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        }

        // 2. Error State (Actual network/parsing failure)
        if (cueSnapshot.hasError) {
          return _buildBaseContainer(
            scenarioSimManager: scenarioSimManager,
            child: const Center(child: Text("Error loading hints.")),
          );
        }

        // 3. Success State (Note: data can be null here if we passed Future.value(null))
        final fetchedCue = cueSnapshot.data;

        return _buildBaseContainer(
          scenarioSimManager: scenarioSimManager,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCloseButton(context, scenarioSimManager),
              const SizedBox(height: 10),

              // Result String (The "Correct!" message)
              if (scenarioSimManager.cueResultStringNotifier.value != null)
                _buildMessageBox(
                  scenarioSimManager.cueResultStringNotifier.value!,
                )
              else
                const SizedBox(height: 25),

              const SizedBox(height: 10),

              // The Hint Text
              _buildMessageBox(
                _getHintText(
                  scenarioSimManager.cueNumberNotifier.value,
                  fetchedCue,
                ),
              ),

              const SizedBox(height: 40),

              MicAndHintButtonCueModal(),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Builders to keep the code clean ---

  Widget _buildBaseContainer({
    required Widget child,
    required ScenarioSimManager scenarioSimManager,
  }) {
    return Container(
      width: double.infinity,
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scenarioSimManager.cueCompleteNotifier.value
            ? AppColors.cueModalComplete
            : AppColors.cueModalInProgress,
        borderRadius: BorderRadius.circular(32.0),
      ),
      child: child,
    );
  }

  Widget _buildMessageBox(String text) {
    return Container(
      width: 375,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColors.hintBackground,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, color: Colors.black),
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildCloseButton(
    BuildContext context,
    ScenarioSimManager scenarioSimManager,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 300));
          scenarioSimManager.updateCueNumber(reset: true);
          scenarioSimManager.resetCueComplete();
          scenarioSimManager.resetCueResultString();
          scenarioSimManager.setIsModalOpen(false);
        },
        icon: const Icon(Icons.close),
        label: const Text('Cancel'),
        style: TextButton.styleFrom(
          side: BorderSide.none,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
    );
  }
}