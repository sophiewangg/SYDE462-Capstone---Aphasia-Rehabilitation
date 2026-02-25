import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import '../../../services/transcription_service.dart';
import '../../../services/cue_service.dart';
import '../../../models/microphone_state.dart';
import '../../../models/cue_model.dart';
import '../../../models/scenario_step.dart';
import '../../../data/restaurant_scenario.dart';
import '../widgets/cue_modal.dart';

class ScenarioSimManager extends ChangeNotifier {
  final List<ScenarioStep> scenarioSteps = restaurantScenarioSteps;

  // --- Services ---
  final TranscriptionService _transcriptionService = TranscriptionService();
  final CueService _cueService = CueService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- State Variables: Transcription ---
  StreamSubscription<TranscriptionResult>? _subscription;
  String _transcription = "";
  bool _hasPermission = false;
  bool _isRecording = false;
  MicrophoneState _currentMicrophoneState = MicrophoneState.idle;

  // --- State Variables: Cue Modal ---
  bool _isModalOpen = false;
  bool _modalIsWordFinding = false;
  String? _likelyWord;
  bool _hintButtonPressed = false;

  // --- State Variables: Scenario Step ---
  int _currentStepIndex = 0;
  String? _promptOverride; // Overrides step prompt after simplification

  // --- ValueNotifiers (For Modal UI) ---
  final cueCompleteNotifier = ValueNotifier<bool>(false);
  final cueResultStringNotifier = ValueNotifier<String?>(null);
  final cueNumberNotifier = ValueNotifier<int>(0);
  final currentMicrophoneStateModal = ValueNotifier<MicrophoneState>(
    MicrophoneState.idle,
  );

  // --- Getters ---
  String get transcription => _transcription;
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  MicrophoneState get currentMicrophoneState => _currentMicrophoneState;
  bool get isModalOpen => _isModalOpen;
  bool get hintButtonPressed => _hintButtonPressed;
  bool get modalIsWordFinding => _modalIsWordFinding;
  int get currentStepIndex => _currentStepIndex;
  String get currentPrompt => _promptOverride ?? _currentStep.prompt;
  String get currentCharacter => _currentStep.characterAsset;
  String get currentAudio =>
      _currentStep.audioAsset ?? "audio_clips/server_speech_1.mp3";

  ScenarioStep get _currentStep => scenarioSteps[_currentStepIndex];

  ScenarioSimManager() {
    _initTranscriptionListener();
    playCharacterAudio(); // Play initial character audio
  }

  // --- Core Transcription Logic ---

  void _initTranscriptionListener() {
    _subscription = _transcriptionService.transcriptionStream.listen((result) {
      _transcription = result.text;
      print("Transcript: $_transcription");
      notifyListeners();

      if (result.isEndOfTurn) {
        handleEndOfTurn();
      }
    });
  }

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    _hasPermission = status.isGranted;
    if (status.isPermanentlyDenied) openAppSettings();
    notifyListeners();
    return _hasPermission;
  }

  void handleMicToggle() {
    if (_isRecording) {
      handleEndOfTurn();
    } else {
      startRecording();
    }
  }

  void startRecording() {
    print("--- 🎙️ STARTING RECORDING ---");
    _transcriptionService.startStreaming();
    _isRecording = true;
    _currentMicrophoneState = MicrophoneState.userSpeaking;
    // Update the modal's internal mic state too
    currentMicrophoneStateModal.value = MicrophoneState.userSpeaking;
    notifyListeners();
  }

  void handleEndOfTurn() {
    stopRecording();
  }

  Future<void> stopRecording() async {
    print("--- 🛑 STOPPING & PROCESSING ---");
    await _transcriptionService.stopStreaming();
    _isRecording = false;
    _currentMicrophoneState = MicrophoneState.processing;
    currentMicrophoneStateModal.value = MicrophoneState.processing;
    notifyListeners();

    if (_isModalOpen) {
      processCueSpeech();
    } else {
      // TODO: actually process speech and determine next step
      // Mock processing: advance to next scenario step
      await Future.delayed(const Duration(seconds: 2));
      _currentStepIndex =
          (_currentStepIndex + 1) % scenarioSteps.length;
      _promptOverride = null; // Clear override when advancing
      _currentMicrophoneState = MicrophoneState.idle;
      currentMicrophoneStateModal.value = MicrophoneState.idle;
      notifyListeners();
      playCharacterAudio();
    }
  }

  // --- Cue Modal Logic ---

  void handleHintPressed({
    required bool isWordFinding,
    required BuildContext context,
  }) async {
    _modalIsWordFinding = isWordFinding;

    // Reset modal state
    cueCompleteNotifier.value = false;
    currentMicrophoneStateModal.value = MicrophoneState.idle;
    _hintButtonPressed = false; // Close the hint selector

    // If recording, stop it immediately without the 2s delay
    if (_isRecording) {
      await _transcriptionService.stopStreaming();
      _isRecording = false;
      _currentMicrophoneState = MicrophoneState.idle;
    }

    notifyListeners();

    if (isWordFinding) {
      final cueFuture = _cueService.getCues(_transcription, currentPrompt);
      _showModal(context, cueFuture);

      final fetchedCue = await cueFuture;
      if (fetchedCue != null) {
        _likelyWord = fetchedCue.likelyWord;
        notifyListeners();
      }
    } else {
      _showModal(context, Future.value(null));
    }
  }

  void processCueSpeech() {
    if (_modalIsWordFinding) {
      _processSpeechWordFinding(_likelyWord ?? "");
    } else {
      _processSpeechUnderstanding();
    }
  }

  void _processSpeechWordFinding(String targetWord) {
    String cleanTranscript = _transcription.toLowerCase().trim();
    String cleanTarget = targetWord.toLowerCase().trim();

    if (cleanTranscript.contains(cleanTarget)) {
      cueCompleteNotifier.value = true;
      cueResultStringNotifier.value =
          "Correct! The word is ${targetWord.toUpperCase()}";
    } else {
      cueResultStringNotifier.value = "Not quite. Here's another hint:";
      updateCueNumber();
    }
    _currentMicrophoneState = MicrophoneState.idle;
    currentMicrophoneStateModal.value = MicrophoneState.idle;
    notifyListeners();
  }

  void _processSpeechUnderstanding() async {
    cueCompleteNotifier.value = true;
    cueResultStringNotifier.value = "Return to exercise.";
    _currentMicrophoneState = MicrophoneState.idle;
    currentMicrophoneStateModal.value = MicrophoneState.idle;
    final response = await _cueService.getSimplifiedPrompt(currentPrompt);
    _promptOverride = response?.simplifiedPrompt ?? _promptOverride;

    notifyListeners();
  }

  void _showModal(BuildContext context, Future<Cue?> fetchedCue) {
    _isModalOpen = true;
    notifyListeners();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CueModal(cueFuture: fetchedCue),
    ).then((_) {
      _isModalOpen = false;
      notifyListeners();
    });
  }
  // --- Character and Audio ---

  void playCharacterAudio() async {
    await _audioPlayer.play(AssetSource(currentAudio));
    await _audioPlayer.onPlayerComplete.first;
  }

  // --- Utilities ---

  void toggleHintButton() {
    _hintButtonPressed = !_hintButtonPressed;
    notifyListeners();
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

  void setIsModalOpen(bool isOpen) {
    _isModalOpen = isOpen;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    cueCompleteNotifier.dispose();
    cueResultStringNotifier.dispose();
    cueNumberNotifier.dispose();
    currentMicrophoneStateModal.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
