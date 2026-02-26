import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import '../../../api_service.dart';
import '../../../services/transcription_service.dart';
import '../../../services/cue_service.dart';
import '../../../models/microphone_state.dart';
import '../../../models/cue_model.dart';
import '../widgets/cue_modal.dart';

// --- ENUMS ---
enum ScenarioStep {
  drinksOffer,
  waterType,
  iceQuestion,
  readyToOrder,
  appetizers,
  steakDoneness,
  sideChoice,
  isThatAll,
  allergies,
  notReadyToOrder,
}

class ScenarioPrompt {
  final String id;
  final String text;
  final String? audioAsset;
  final String? imageAsset;
  const ScenarioPrompt({
    required this.id,
    required this.text,
    this.audioAsset,
    this.imageAsset,
  });
}

class ScenarioSimManager extends ChangeNotifier {
  // --- Services ---
  final TranscriptionService _transcriptionService = TranscriptionService();
  final ScenarioApiService _scenarioApiService = ScenarioApiService();
  final CueService _cueService = CueService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- State Variables: Transcription & Mic ---
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

  // --- State Variables: Scenario Progression ---
  ScenarioStep _currentStep = ScenarioStep.drinksOffer;
  String? _systemMessage;
  String? _promptPrefix;
  String? _promptOverride;
  final List<String> _orderItems = [];

  final Map<ScenarioStep, ScenarioPrompt> _prompts = {
    ScenarioStep.drinksOffer: const ScenarioPrompt(
      id: 'drinks_offer',
      text: "Here's the menu. Can I get you started with any drinks?",
    ),
    ScenarioStep.waterType: const ScenarioPrompt(
      id: 'water_type',
      text: "Still or sparkling?",
    ),
    ScenarioStep.iceQuestion: const ScenarioPrompt(
      id: 'ice_question',
      text: "Would you like ice with it?",
    ),
    ScenarioStep.readyToOrder: const ScenarioPrompt(
      id: 'ready_to_order',
      text: "Are you ready to order?",
    ),
    ScenarioStep.appetizers: const ScenarioPrompt(
      id: 'appetizers',
      text: "Any appetizers to get you started?",
    ),
    ScenarioStep.steakDoneness: const ScenarioPrompt(
      id: 'steak_doneness',
      text: "How would you like your steak?",
    ),
    ScenarioStep.sideChoice: const ScenarioPrompt(
      id: 'side_choice',
      text: "Would you like salad or fries as your side?",
    ),
    ScenarioStep.isThatAll: const ScenarioPrompt(
      id: 'is_that_all',
      text: "Is that all for you?",
    ),
    ScenarioStep.allergies: const ScenarioPrompt(
      id: 'allergies',
      text: "Do you have any allergies?",
    ),
  };

  // --- State Variables: Character and Audio ---
  String currentCharacter = "assets/characters/server_1.png";
  String currentAudio = "audio_clips/server_speech_1.mp3";

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
  String? get systemMessage => _systemMessage;

  String get currentPrompt {
    final base = _prompts[_currentStep]?.text ?? "";
    if (_promptOverride != null) return _promptOverride!;
    if (_promptPrefix != null) return "${_promptPrefix!}$base";
    return base;
  }

  ScenarioSimManager() {
    _initTranscriptionListener();
    _playPromptAndListen();
  }

  // --- Core Scenario Flow Logic ---

  Future<void> _playPromptAndListen() async {
    _currentMicrophoneState = MicrophoneState.idle;
    notifyListeners();

    final prompt = _prompts[_currentStep];
    if (prompt?.audioAsset != null) {
      await _audioPlayer.play(AssetSource(prompt!.audioAsset!));
      await _audioPlayer.onPlayerComplete.first;
    }

    startRecording();
  }

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
      final transcript = _transcription.trim();

      if (transcript.isEmpty) {
        _promptPrefix = "I didn't quite hear that. Could you try again? ";
        startRecording();
        return;
      }

      final classification = await _scenarioApiService.classifyUtterance(
        transcript,
      );

      if (classification == null || !classification.match) {
        _systemMessage =
            "I'm not sure I understood. Could you try saying that another way?";
        startRecording();
        return;
      }

      if (_currentStep == ScenarioStep.allergies) {
        // UI should listen for completion, but logic ends here
        return;
      }

      _advanceScenario(classification.intent);
      await _playPromptAndListen();
    }
  }

  void _advanceScenario(String? intent) {
    if (intent != 'ready_no') {
      _promptOverride = null;
      _promptPrefix = null;
      _systemMessage = null;
    }

    switch (_currentStep) {
      case ScenarioStep.drinksOffer:
        if (intent == 'beverage_water')
          _currentStep = ScenarioStep.waterType;
        else if (intent == 'water_still' ||
            intent == 'water_sparkling' ||
            intent == 'beverage_other')
          _currentStep = ScenarioStep.iceQuestion;
        break;
      case ScenarioStep.waterType:
        if (intent == 'water_still' || intent == 'water_sparkling')
          _currentStep = ScenarioStep.iceQuestion;
        break;
      case ScenarioStep.iceQuestion:
        _currentStep = ScenarioStep.readyToOrder;
        break;
      case ScenarioStep.readyToOrder:
        if (intent == 'ready_yes') {
          _promptOverride = null;
          _systemMessage = null;
          _currentStep = ScenarioStep.appetizers;
        } else if (intent == 'ready_no') {
          _promptOverride =
              "No problem, just say 'I'm ready to order' when you've decided.";
        }
        break;
      case ScenarioStep.appetizers:
        if (intent == 'ask_specials' || intent == 'ask_soup')
          _systemMessage = "Today's soup is creamy roasted garlic.";
        else if (intent == 'ask_recommendations')
          _systemMessage = "My personal favourite is the lobster pasta.";
        else if (intent == 'order_steak')
          _currentStep = ScenarioStep.steakDoneness;
        else if (intent == 'order_chicken' || intent == 'order_pasta') {
          _orderItems.add(intent!);
          _currentStep = ScenarioStep.isThatAll;
        }
        break;
      case ScenarioStep.steakDoneness:
        if (intent == 'steak_doneness') _currentStep = ScenarioStep.sideChoice;
        break;
      case ScenarioStep.sideChoice:
        if (intent == 'side_salad' || intent == 'side_fries') {
          _orderItems.add(intent!);
          _currentStep = ScenarioStep.isThatAll;
        }
        break;
      case ScenarioStep.isThatAll:
        if (intent == 'is_that_all_yes')
          _currentStep = ScenarioStep.allergies;
        else if (intent == 'is_that_all_no')
          _currentStep = ScenarioStep.appetizers;
        break;
      case ScenarioStep.allergies:
      case ScenarioStep.notReadyToOrder:
        break;
    }
    notifyListeners();
  }

  // --- Cue Modal Logic (Restored) ---

  void handleHintPressed({
    required bool isWordFinding,
    required BuildContext context,
  }) async {
    _modalIsWordFinding = isWordFinding;
    cueCompleteNotifier.value = false;
    currentMicrophoneStateModal.value = MicrophoneState.idle;
    _hintButtonPressed = false;

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

    // Note: We're applying the simplified prompt via _promptOverride
    // so it doesn't permanently overwrite the base step text.
    _promptOverride = response?.simplifiedPrompt ?? currentPrompt;
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
    if (reset)
      cueNumberNotifier.value = 0;
    else
      cueNumberNotifier.value = cueNumberNotifier.value + 1;
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

  void handleUserTurnCompleted() {
    handleEndOfTurn();
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
