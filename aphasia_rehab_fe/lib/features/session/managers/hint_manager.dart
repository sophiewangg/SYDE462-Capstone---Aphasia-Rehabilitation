import 'dart:io';
import 'dart:typed_data';

import 'package:aphasia_rehab_fe/services/eleven_labs_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/cue_model.dart';
import '../../../services/cue_service.dart';
import '../widgets/cue_modal.dart';
import 'dashboard_manager.dart';

/// Manages the hint flow: word-finding cues (with describe phase) and
/// "I don't understand" prompt simplification.
class HintManager extends ChangeNotifier {
  final CueService _cueService = CueService();
  final DashboardManager dashboardManager;
  final ElevenLabsService _elevenLabsService = ElevenLabsService();

  bool _isModalOpen = false;
  bool _modalIsWordFinding = false;
  String? _likelyWord;
  String? _cueDescriptionTranscript;
  bool _hintButtonPressed = false;
  bool _isLoading = false;
  Cue? _currentCue;
  String _hintText = '';
  Cue? _fetchedCue;
  String _currentCachedAudioId = '';

  final cueCompleteNotifier = ValueNotifier<bool>(false);
  final cueResultStringNotifier = ValueNotifier<String?>(null);
  final cueNumberNotifier = ValueNotifier<int>(0);
  final cueFutureNotifier = ValueNotifier<Future<Cue?>?>(null);

  String Function() getCurrentPrompt;
  Future<void> Function(String, dynamic) onPromptSimplified;
  Future<void> Function() requestStopRecording;
  void Function() onProcessingComplete;
  void Function()? onEnterDescribePhase;

  final AudioPlayer _hintPlayer = AudioPlayer();

  HintManager({
    required this.getCurrentPrompt,
    required this.onPromptSimplified,
    required this.requestStopRecording,
    required this.onProcessingComplete,
    required this.dashboardManager,
    this.onEnterDescribePhase,
  });

  bool get isModalOpen => _isModalOpen;
  bool get hintButtonPressed => _hintButtonPressed;
  bool get modalIsWordFinding => _modalIsWordFinding;
  bool get isHintDescribePhase =>
      _modalIsWordFinding && cueFutureNotifier.value == null;
  String get hintText => _hintText;
  Cue? get currentCue => _currentCue;
  String get currentCachedAudioId => _currentCachedAudioId;

  bool get isLoading => _isLoading;

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
      _hintText = "Try describing the word";
      notifyListeners();
      _showModal(context);
      playElevenLabsAudio(_hintText, 'describe-audio');
      _currentCachedAudioId = 'describe-audio';
    } else {
      cueFutureNotifier.value = Future.value(null);
      _hintText = "Try saying \"I didn't understand that\"";
      notifyListeners();
      _showModal(context);
      playElevenLabsAudio(_hintText, 'dont-understand-audio');
      _currentCachedAudioId = 'dont-understand-audio';
    }
  }

  void onTranscriptReceived(
    String transcript,
    ImageConfiguration config,
  ) async {
    if (_modalIsWordFinding && _cueDescriptionTranscript == null) {
      _cueDescriptionTranscript = transcript.trim();
      if (_cueDescriptionTranscript!.isEmpty) {
        cueResultStringNotifier.value =
            "I didn't hear that. Please describe the word again.";
        onProcessingComplete();
        notifyListeners();
        return;
      }
      final cueFuture = _cueService.getCues(
        _cueDescriptionTranscript!,
        getCurrentPrompt(),
      );
      cueFutureNotifier.value = cueFuture;
      cueNumberNotifier.value = 1;
      _fetchedCue = await cueFuture;
      updateHintText(cueNumberNotifier.value);
      if (_fetchedCue != null) _likelyWord = _fetchedCue!.likelyWord;
      cueResultStringNotifier.value = null;
      onProcessingComplete();
      notifyListeners();
    } else {
      _processTranscript(transcript, config);
    }
  }

  void _processTranscript(String transcript, ImageConfiguration config) {
    if (_modalIsWordFinding) {
      _processWordFinding(transcript, _likelyWord ?? "");
    } else {
      _processUnderstanding(config);
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
      updateHintText(cueNumberNotifier.value);
    }
    onProcessingComplete();
    notifyListeners();
  }

  void _processUnderstanding(ImageConfiguration config) async {
    cueCompleteNotifier.value = true;
    cueResultStringNotifier.value = "Return to exercise.";
    onProcessingComplete();
    final response = await _cueService.getSimplifiedPrompt(getCurrentPrompt());
    onPromptSimplified(
      response?.simplifiedPrompt ?? getCurrentPrompt(),
      config,
    );
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

  void closeModal(String promptText) {
    cueFutureNotifier.value = null;
    _isModalOpen = false;

    // Update metrics for dahsboard
    dashboardManager.cueComplete(
      cueNumberNotifier.value,
      _likelyWord ?? promptText,
    );

    notifyListeners();
  }

  void updateHintText(int stage) {
    if (_fetchedCue == null) {
      return;
    }

    switch (stage) {
      case 1:
        _hintText = "Try a word that rhymes with: ${_fetchedCue!.rhyming}";
        playElevenLabsAudio(_hintText, 'rhyme-audio');
        _currentCachedAudioId = 'rhyme-audio';
        notifyListeners();

        return;
      case 2:
        _hintText =
            "Try a word that starts with: ${_fetchedCue!.firstSound.toUpperCase()}";
        playElevenLabsAudio(_hintText, 'first-letter-audio');
        _currentCachedAudioId = 'first-letter-audio';
        notifyListeners();

        return;
      default:
        _hintText = "Try the word: ${_fetchedCue!.likelyWord.toUpperCase()}";
        playElevenLabsAudio(_hintText, 'answer-audio');
        _currentCachedAudioId = 'answer-audio';

        notifyListeners();
        return;
    }
  }

  Future<void> playElevenLabsAudio(String text, String promptId) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/audio_$promptId.mp3';
    final file = File(filePath);

    if (await file.exists()) {
      print("Playing from local cache: $filePath");
      await  _hintPlayer.setFilePath(filePath);
    } else {
      print("Fetching from ElevenLabs API...");
      Uint8List audioBytes = await _elevenLabsService.fetchAudio(text);
      await file.writeAsBytes(audioBytes);
      await _hintPlayer.setFilePath(filePath);
    }

    await _hintPlayer.play();
  }

  Future<void> _clearHintAudioCache() async {
    try {
      List<String> idsToClear = [
        'dont-understand-audio',
        'describe-audio',
        'rhyme-audio',
        'first-letter-audio',
        'answer-audio',
      ];
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync();

      for (var file in files) {
        if (file is File) {
          // Check if the file name contains 'audio_' AND any of the target IDs
          final bool shouldDelete = idsToClear.any(
            (id) => file.path.contains('audio_$id'),
          );

          if (shouldDelete) {
            await file.delete();
            print("Deleted specific cached audio: ${file.path}");
          }
        }
      }
    } catch (e) {
      print("Error clearing specific cache: $e");
    }
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
    _clearHintAudioCache();
    _currentCachedAudioId = '';
    notifyListeners();
  }

  @override
  void dispose() {
    cueCompleteNotifier.dispose();
    cueResultStringNotifier.dispose();
    cueNumberNotifier.dispose();
    cueFutureNotifier.dispose();
    _hintPlayer.dispose();

    super.dispose();
  }
}
