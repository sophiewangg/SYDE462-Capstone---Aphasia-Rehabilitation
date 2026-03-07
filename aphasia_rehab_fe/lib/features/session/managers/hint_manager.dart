import 'package:flutter/material.dart';

import '../../../models/cue_model.dart';
import '../../../services/cue_service.dart';
import '../widgets/cue_modal.dart';

/// Manages the hint flow: word-finding cues (with describe phase) and
/// "I don't understand" prompt simplification.
class HintManager extends ChangeNotifier {
  final CueService _cueService = CueService();

  bool _isModalOpen = false;
  bool _modalIsWordFinding = false;
  String? _likelyWord;
  String? _cueDescriptionTranscript;
  bool _hintButtonPressed = false;

  final cueCompleteNotifier = ValueNotifier<bool>(false);
  final cueResultStringNotifier = ValueNotifier<String?>(null);
  final cueNumberNotifier = ValueNotifier<int>(0);
  final cueFutureNotifier = ValueNotifier<Future<Cue?>?>(null);

  String Function() getCurrentPrompt;
  void Function(String) onPromptSimplified;
  Future<void> Function() requestStopRecording;
  void Function() onProcessingComplete;
  void Function()? onEnterDescribePhase;

  HintManager({
    required this.getCurrentPrompt,
    required this.onPromptSimplified,
    required this.requestStopRecording,
    required this.onProcessingComplete,
    this.onEnterDescribePhase,
  });

  bool get isModalOpen => _isModalOpen;
  bool get hintButtonPressed => _hintButtonPressed;
  bool get modalIsWordFinding => _modalIsWordFinding;
  bool get isHintDescribePhase =>
      _modalIsWordFinding && cueFutureNotifier.value == null;

  void toggleHintButton() {
    _hintButtonPressed = !_hintButtonPressed;
    notifyListeners();
  }

  void startHintFlow({
    required bool isWordFinding,
    required BuildContext context,
  }) async {
    _modalIsWordFinding = isWordFinding;
    cueCompleteNotifier.value = false;
    _hintButtonPressed = false;

    await requestStopRecording();
    if (!context.mounted) return;
    notifyListeners();

    if (isWordFinding) {
      _cueDescriptionTranscript = null;
      cueFutureNotifier.value = null;
      onEnterDescribePhase?.call();
      _showModal(context);
    } else {
      cueFutureNotifier.value = Future.value(null);
      _showModal(context);
    }
  }

  void onTranscriptReceived(String transcript) async {
    if (_modalIsWordFinding && _cueDescriptionTranscript == null) {
      _cueDescriptionTranscript = transcript.trim();
      if (_cueDescriptionTranscript!.isEmpty) {
        cueResultStringNotifier.value =
            "I didn't hear that. Please describe the word again.";
        onProcessingComplete();
        notifyListeners();
        return;
      }
      final cueFuture =
          _cueService.getCues(_cueDescriptionTranscript!, getCurrentPrompt());
      cueFutureNotifier.value = cueFuture;
      cueNumberNotifier.value = 2;
      final fetchedCue = await cueFuture;
      if (fetchedCue != null) _likelyWord = fetchedCue.likelyWord;
      cueResultStringNotifier.value = null;
      onProcessingComplete();
      notifyListeners();
    } else {
      _processTranscript(transcript);
    }
  }

  void _processTranscript(String transcript) {
    if (_modalIsWordFinding) {
      _processWordFinding(transcript, _likelyWord ?? "");
    } else {
      _processUnderstanding();
    }
  }

  void _processWordFinding(String transcript, String targetWord) {
    final cleanTranscript = transcript.toLowerCase().trim();
    final cleanTarget = targetWord.toLowerCase().trim();

    if (cleanTranscript.contains(cleanTarget)) {
      cueCompleteNotifier.value = true;
      cueResultStringNotifier.value =
          "Correct! The word is ${targetWord.toUpperCase()}";
    } else {
      cueResultStringNotifier.value = "Not quite. Here's another hint:";
      updateCueNumber();
    }
    onProcessingComplete();
    notifyListeners();
  }

  void _processUnderstanding() async {
    cueCompleteNotifier.value = true;
    cueResultStringNotifier.value = "Return to exercise.";
    onProcessingComplete();
    final response = await _cueService.getSimplifiedPrompt(getCurrentPrompt());
    onPromptSimplified(response?.simplifiedPrompt ?? getCurrentPrompt());
    notifyListeners();
  }

  void _showModal(BuildContext context) {
    _isModalOpen = true;
    notifyListeners();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CueModal(),
    ).then((_) {
      _isModalOpen = false;
      _cueDescriptionTranscript = null;
      cueFutureNotifier.value = null;
      notifyListeners();
    });
  }

  void updateCueNumber({bool reset = false}) {
    if (reset) {
      cueNumberNotifier.value = 0;
    } else {
      cueNumberNotifier.value = cueNumberNotifier.value + 1;
    }
    notifyListeners();
  }

  void resetCueComplete() {
    cueCompleteNotifier.value = false;
    notifyListeners();
  }

  void resetCueResultString() {
    cueResultStringNotifier.value = null;
    notifyListeners();
  }

  void closeModal() {
    cueFutureNotifier.value = null;
    _isModalOpen = false;
    notifyListeners();
  }

  void reset() {
    _isModalOpen = false;
    _modalIsWordFinding = false;
    _likelyWord = null;
    _cueDescriptionTranscript = null;
    _hintButtonPressed = false;
    cueCompleteNotifier.value = false;
    cueResultStringNotifier.value = null;
    cueNumberNotifier.value = 0;
    cueFutureNotifier.value = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cueCompleteNotifier.dispose();
    cueResultStringNotifier.dispose();
    cueNumberNotifier.dispose();
    cueFutureNotifier.dispose();
    super.dispose();
  }
}
