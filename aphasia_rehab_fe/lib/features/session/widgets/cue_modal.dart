import 'package:aphasia_rehab_fe/colors.dart';
import 'package:aphasia_rehab_fe/features/session/managers/hint_manager.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/cue_audio_button.dart';
import 'package:aphasia_rehab_fe/features/session/widgets/mic_and_hint_button_cue_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CueModal extends StatefulWidget {
  const CueModal({super.key});

  @override
  State<CueModal> createState() => _CueModalState();
}

class _CueModalState extends State<CueModal> {
  bool _autoCloseScheduled = false;

  void _scheduleAutoClose(BuildContext context, HintManager hintManager) {
    if (_autoCloseScheduled) return;
    _autoCloseScheduled = true;

    // Capture dependencies while the context is still safely mounted.
    final scenarioSimManager = context.read<ScenarioSimManager>();
    final bool modalWasWordFinding = hintManager.modalIsWordFinding;
    final config = createLocalImageConfiguration(context);

    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!context.mounted) return;
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 300));

      hintManager.closeModal(hintManager.getCurrentPrompt());
      hintManager.updateCueNumber(reset: true);
      hintManager.resetCueComplete();
      hintManager.resetCueResultString();
      scenarioSimManager.resetTranscription();

      // After the hint flow completes and the modal closes,
      // re-ask the current dialogue by replaying the audio.
      // if prompt override, the audio playing is handled in _handlePromptOverride
      if (modalWasWordFinding &&
          scenarioSimManager.promptOverride == null &&
          scenarioSimManager.promptPrefix == null) {
        await scenarioSimManager.playCharacterAudio(config, null);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hintManager = context.watch<HintManager>();
    final scenarioSimManager = context.watch<ScenarioSimManager>();

    if (hintManager.cueCompleteNotifier.value) {
      _scheduleAutoClose(context, hintManager);
      return _buildCompleteState(context, hintManager);
    }

    if (hintManager.isLoading) {
      return _buildBaseContainer(
        hintManager: hintManager,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.yellowSecondary,
            ),
            strokeWidth: 3,
          ),
        ),
      );
    }

    return _buildBaseContainer(
      hintManager: hintManager,
      child: Column(
        children: [
          _buildCloseButton(context, hintManager),
          _buildMessageBox(hintManager.hintText),
          const SizedBox(height: 12),
          Text(
            scenarioSimManager.transcription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 24),
          MicAndHintButtonCueModal(showHintButton: false),
        ],
      ),
    );
  }

  Widget _buildBaseContainer({
    required Widget child,
    required HintManager hintManager,
  }) {
    return Container(
      width: double.infinity,
      height: 350,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CueAudioButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, color: Colors.black),
              textAlign: TextAlign.start,
            ),
          ),
        ],
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
          scenarioSimManager.resetTranscription();
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
