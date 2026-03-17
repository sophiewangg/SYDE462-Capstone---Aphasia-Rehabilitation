import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/hint_manager.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button_cue_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/cue_model.dart';

class CueModal extends StatefulWidget {
  const CueModal({super.key});

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
        return "Try a word that rhymes with: ${fetchedCue.rhyming}";
      case 2:
        return "Try a word that starts with: ${fetchedCue.firstSound.toUpperCase()}";
      default:
        return "Try the word: ${fetchedCue.likelyWord.toUpperCase()}";
    }
  }

  void _scheduleAutoClose(BuildContext context, HintManager hintManager) {
    if (_autoCloseScheduled) return;
    _autoCloseScheduled = true;

    // Capture dependencies while the context is still safely mounted.
    final scenarioSimManager = context.read<ScenarioSimManager>();
    final config = createLocalImageConfiguration(context);

    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!context.mounted) return;
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 300));

      hintManager.closeModal(hintManager.getCurrentPrompt());
      hintManager.updateCueNumber(reset: true);
      hintManager.resetCueComplete();
      hintManager.resetCueResultString();

      // After the hint flow completes and the modal closes,
      // re-ask the current dialogue by replaying the audio.
      if (scenarioSimManager.promptOverride == null &&
          scenarioSimManager.promptPrefix == null) {
        await scenarioSimManager.playCharacterAudio(config, null);
      } else {
        await scenarioSimManager.playElevenLabsAudio(
          scenarioSimManager.currentDialogue,
          'override-prompt',
        );
      }
    });
  }

  Widget _buildCompleteState(BuildContext context, HintManager hintManager) {
    final resultText = hintManager.cueResultStringNotifier.value ?? "Done.";
    return _buildBaseContainer(
      hintManager: hintManager,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCloseButton(context, hintManager),
          const SizedBox(height: 12),
          _buildMessageBox(resultText),
          const SizedBox(height: 12),
          MicAndHintButtonCueModal(showHintButton: false),
          ],
        ),
      )      
    );
  }

  Widget _buildDescribePhase(BuildContext context, HintManager hintManager) {
  return _buildBaseContainer(
    hintManager: hintManager,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCloseButton(context, hintManager),
          const SizedBox(height: 12),
          _buildMessageBox("Try describing the word"),
          const SizedBox(height: 12),
          if (hintManager.cueResultStringNotifier.value != null)
            _buildMessageBox(hintManager.cueResultStringNotifier.value!),
            const SizedBox(height: 12),
          MicAndHintButtonCueModal(showHintButton: false),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final hintManager = context.watch<HintManager>();

    // Trigger auto-close when the modal turns green
    if (hintManager.cueCompleteNotifier.value) {
      _scheduleAutoClose(context, hintManager);
      // When complete, always show success UI (never SizedBox.shrink) so the
      // modal has proper content for the closing animation
      return _buildCompleteState(context, hintManager);
    }

    if (hintManager.isHintDescribePhase) {
      return ValueListenableBuilder<String?>(
        valueListenable: hintManager.cueResultStringNotifier,
        builder: (_, __, ___) => _buildDescribePhase(context, hintManager),
      );
    }

    final cueFuture = hintManager.cueFutureNotifier.value;
    if (cueFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Cue?>(
      future: cueFuture,
      builder: (context, cueSnapshot) {
        if (cueSnapshot.connectionState == ConnectionState.waiting) {
          return _buildBaseContainer(
            hintManager: hintManager,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        }

        if (cueSnapshot.hasError) {
          return _buildBaseContainer(
            hintManager: hintManager,
            child: const Center(child: Text("Error loading hints.")),
          );
        }

        final fetchedCue = cueSnapshot.data;

        return _buildBaseContainer(
          hintManager: hintManager,
          child: Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCloseButton(context, hintManager),
              if (hintManager.cueResultStringNotifier.value != null)
                _buildMessageBox(hintManager.cueResultStringNotifier.value!),
              const SizedBox(height: 12),
              _buildMessageBox(
                _getHintText(hintManager.cueNumberNotifier.value, fetchedCue),
              ),
              const SizedBox(height: 24),
              MicAndHintButtonCueModal(showHintButton: false),
              ],
            ),
          )
          
        );
      },
    );
  }

  Widget _buildBaseContainer({
    required Widget child,
    required HintManager hintManager,
  }) {
    return Container(
      width: double.infinity,
      // height: 300,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: hintManager.cueCompleteNotifier.value
            ? AppColors.cueModalComplete
            : AppColors.yellowTertiary,
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

  Widget _buildCloseButton(BuildContext context, HintManager hintManager) {
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 300));
          hintManager.updateCueNumber(reset: true);
          hintManager.resetCueComplete();
          hintManager.resetCueResultString();
          hintManager.closeModal(scenarioSimManager.currentPrompt!.promptText);
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
