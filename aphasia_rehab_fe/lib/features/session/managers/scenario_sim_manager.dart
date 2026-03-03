import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import '../../../api_service.dart';
import '../../../services/transcription_service.dart';
import '../../../models/microphone_state.dart';
import 'hint_manager.dart';

// --- ENUMS ---
enum ScenarioStep {
  drinksOffer,
  waterType,
  iceQuestion,
  readyToOrder,
  appetizers,
  entrees,
  steakDoneness,
  sideChoice,
  isThatAll,
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
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- State Variables: Transcription & Mic ---
  late final HintManager hintManager;

  StreamSubscription<TranscriptionResult>? _subscription;
  String _transcription = "";
  bool _hasPermission = false;
  bool _isRecording = false;
  MicrophoneState _currentMicrophoneState = MicrophoneState.idle;

  // --- State Variables: Scenario Progression ---
  ScenarioStep _currentStep = ScenarioStep.drinksOffer;
  String? _systemMessage;
  String? _promptPrefix;
  String? _promptOverride;
  final List<String> _orderItems = [];
  bool _hasAnsweredSteakDoneness = false; // Added flag for dynamic routing

  // --- State Variables: Scenario Status ---
  bool _isBobEateryModalOpen = false;
  bool _isScenarioComplete = false;

  bool get isScenarioComplete => _isScenarioComplete;

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
    ScenarioStep.entrees: const ScenarioPrompt(
      id: 'entrees',
      text: 'Would you like to order any entrees?',
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
  };

  // --- State Variables: Character and Audio ---
  String currentCharacter = "assets/characters/server_1.png";
  String currentAudio = "audio_clips/server_speech_1.mp3";

  // --- Getters ---
  String get transcription => _transcription;
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  MicrophoneState get currentMicrophoneState => _currentMicrophoneState;
  String? get systemMessage => _systemMessage;
  bool get isBobEateryModalOpen => _isBobEateryModalOpen;

  String get currentPrompt {
    final base = _prompts[_currentStep]?.text ?? "";
    if (_promptOverride != null) return _promptOverride!;
    if (_promptPrefix != null) return "${_promptPrefix!}$base";
    return base;
  }

  ScenarioSimManager() {
    hintManager = HintManager(
      getCurrentPrompt: () => currentPrompt,
      onPromptSimplified: (text) {
        _promptOverride = text;
        notifyListeners();
      },
      requestStopRecording: () async {
        if (_isRecording) {
          await _transcriptionService.stopStreaming();
          _isRecording = false;
          _currentMicrophoneState = MicrophoneState.idle;
          notifyListeners();
        }
      },
      onProcessingComplete: () {
        _currentMicrophoneState = MicrophoneState.idle;
        notifyListeners();
      },
      onEnterDescribePhase: () {
        _transcription = "";
      },
    );
    _initTranscriptionListener();
    _playPrompt();
  }

  // --- Core Scenario Flow Logic ---

  Future<void> _playPrompt() async {
    final prompt = _prompts[_currentStep];
    if (prompt?.audioAsset != null) {
      await _audioPlayer.play(AssetSource(prompt!.audioAsset!));
      await _audioPlayer.onPlayerComplete.first;
    }
  }

  void _initTranscriptionListener() {
    _subscription = _transcriptionService.transcriptionStream.listen((result) {
      _transcription = result.text;
      print("Transcript: $_transcription");
      notifyListeners();
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
    notifyListeners();
  }

  Future<void> handleEndOfTurn() async {
    // Update UI immediately so button switches right away
    _isRecording = false;
    _currentMicrophoneState = MicrophoneState.processing;
    notifyListeners();
    // Wait for 1 second to not cut off words currently being transcribed
    await Future.delayed(const Duration(seconds: 1));

    stopRecording();
  }

  Future<void> stopRecording() async {
    print("--- 🛑 STOPPING & PROCESSING ---");
    await _transcriptionService.stopStreaming();
    _isRecording = false;
    _currentMicrophoneState = MicrophoneState.processing;
    notifyListeners();

    if (hintManager.isModalOpen) {
      hintManager.onTranscriptReceived(_transcription);
      return;
    }

    final transcript = _transcription.trim();

    if (transcript.isEmpty) {
      _promptPrefix = "I didn't quite hear that. Could you try again? ";
      _currentMicrophoneState = MicrophoneState.idle;
      notifyListeners();
      return;
    }

    final classification = await _scenarioApiService.classifyUtterance(
      transcript,
    );

    if (classification == null || !classification.match) {
      _systemMessage =
          "I'm not sure I understood. Could you try saying that another way?";
      _currentMicrophoneState = MicrophoneState.idle;
      notifyListeners();
      return;
    }

    if (_currentStep == ScenarioStep.allergies) {
      _isScenarioComplete = true;
      notifyListeners();
      return;
    }

    _advanceScenario(classification.intent);
    _currentMicrophoneState = MicrophoneState.idle;
    notifyListeners();
  }

  void _advanceScenario(List<String> intents) {
    if (!intents.contains('ready_no')) {
      _promptOverride = null;
      _promptPrefix = null;
      _systemMessage = null;
    }

    // 1. Process all detected food items, irrespective of the current step
    bool orderedNewItems = false;
    for (String intent in intents) {
      if (intent.startsWith('order_') || intent.startsWith('side_')) {
        if (!_orderItems.contains(intent)) {
          _orderItems.add(intent);
          orderedNewItems = true;
        }
      }
    }

    // 2. Step-based logic
    switch (_currentStep) {
      case ScenarioStep.drinksOffer:
        if (intents.contains('beverage_water')) {
          _currentStep = ScenarioStep.waterType;
        } else if (intents.contains('water_still') ||
            intents.contains('water_sparkling') ||
            intents.contains('beverage_other')) {
          _currentStep = ScenarioStep.iceQuestion;
        }
        break;
      case ScenarioStep.waterType:
        if (intents.contains('water_still') ||
            intents.contains('water_sparkling')) {
          _currentStep = ScenarioStep.iceQuestion;
        }
        break;
      case ScenarioStep.iceQuestion:
        _currentStep = ScenarioStep.readyToOrder;
        break;
      case ScenarioStep.readyToOrder:
        if (intents.contains('ready_no')) {
          _promptOverride =
              "No problem, just say 'I'm ready to order' when you've decided.";
        } else if (intents.contains('ready_yes') || orderedNewItems) {
          _currentStep = _determineNextLogicalStep();
        }
        break;
      case ScenarioStep.appetizers:
      case ScenarioStep.entrees:
        if (intents.contains('ask_specials') || intents.contains('ask_soup')) {
          _systemMessage = "Today's soup is creamy roasted garlic.";
        } else if (intents.contains('ask_recommendations')) {
          _systemMessage = "My personal favourite is the lobster pasta.";
        } else if (orderedNewItems) {
          _currentStep = _determineNextLogicalStep();
        } else if (intents.contains('no_appetizer') ||
            intents.contains('no_entrees')) {
          _currentStep = _determineNextLogicalStep();
        }
        break;
      case ScenarioStep.steakDoneness:
        if (intents.contains('steak_doneness')) {
          _hasAnsweredSteakDoneness = true;
          _currentStep = _determineNextLogicalStep();
        }
        break;
      case ScenarioStep.sideChoice:
        if (orderedNewItems) {
          _currentStep = _determineNextLogicalStep();
        }
        break;
      case ScenarioStep.isThatAll:
        if (intents.contains('is_that_all_yes')) {
          _isScenarioComplete = true; // Trigger ending sequence
        } else if (intents.contains('is_that_all_no')) {
          _currentStep = ScenarioStep.appetizers; // Loop back
        }
        break;
      case ScenarioStep.notReadyToOrder:
        break;
    }
    notifyListeners();
  }

  ScenarioStep _determineNextLogicalStep() {
    if (_orderItems.contains('order_steak') && !_hasAnsweredSteakDoneness) {
      return ScenarioStep.steakDoneness;
    }

    // Check for combinations
    bool hasEntree = _orderItems.any(
      (item) => ['order_steak', 'order_chicken', 'order_pasta'].contains(item),
    );
    bool hasSide = _orderItems.any(
      (item) => ['side_salad', 'side_fries'].contains(item),
    );

    if (hasEntree && !hasSide) {
      return ScenarioStep.sideChoice;
    }

    if (!hasEntree && _currentStep != ScenarioStep.entrees) {
      return ScenarioStep.entrees;
    }
    return ScenarioStep.isThatAll;
  }

  void resetScenario() {
    print("--- 🔄 RESETTING SCENARIO ---");

    // Reset core progression
    _currentStep = ScenarioStep.drinksOffer;
    _isScenarioComplete = false;
    _hasAnsweredSteakDoneness = false;
    _orderItems.clear();

    // Reset text states
    _transcription = "";
    _systemMessage = null;
    _promptPrefix = null;
    _promptOverride = null;

    hintManager.reset();

    // Make sure audio is stopped
    _audioPlayer.stop();
    if (_isRecording) {
      _transcriptionService.stopStreaming();
      _isRecording = false;
      _currentMicrophoneState = MicrophoneState.idle;
    }

    notifyListeners();
  }

  // --- Character and Audio ---
  void playCharacterAudio() async {
    await _audioPlayer.play(AssetSource(currentAudio));
    await _audioPlayer.onPlayerComplete.first;
  }

  // --- Utilities ---
  void handleUserTurnCompleted() {
    handleEndOfTurn();
  }

  void toggleBobEateryModal() {
    _isBobEateryModalOpen = !_isBobEateryModalOpen;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    hintManager.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
