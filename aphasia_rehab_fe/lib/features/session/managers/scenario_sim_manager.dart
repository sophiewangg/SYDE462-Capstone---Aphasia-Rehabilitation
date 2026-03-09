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
  reservation,
  reservationName,
  numberPeople,
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
  howIsEverything,
  areYouDone,
  readyForBill,
  paymentMethod,
  receipt,
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

  // Define which steps should allow the user to order anything from the menu
  final List<ScenarioStep> _globalSearchSteps = [
    ScenarioStep.drinksOffer,
    ScenarioStep.readyToOrder,
    ScenarioStep.appetizers,
    ScenarioStep.entrees,
  ];

  // --- State Variables: Transcription & Mic ---
  late final HintManager hintManager;

  StreamSubscription<TranscriptionResult>? _subscription;
  String _transcription = "";
  bool _hasPermission = false;
  bool _isRecording = false;
  MicrophoneState _currentMicrophoneState = MicrophoneState.idle;

  // --- State Variables: Scenario Progression ---
  ScenarioStep _currentStep = ScenarioStep.reservation;
  String? _systemMessage;
  String? _promptPrefix;
  String? _promptOverride;
  final List<String> _orderItems = [];

  // Dynamic Routing Flags
  bool _hasAnsweredSteakDoneness = false;
  bool _wantsNoAppetizers = false;
  bool _wantsNoEntrees = false;

  // --- State Variables: Scenario Status ---
  bool _isBobEateryModalOpen = false;
  bool _isScenarioComplete = false;

  bool get isScenarioComplete => _isScenarioComplete;

  final Map<ScenarioStep, ScenarioPrompt> _prompts = {
    ScenarioStep.reservation: const ScenarioPrompt(
      id: 'reservation',
      text: "Welcome to Bob's Eatery. Do you have a reservation?",
    ),
    ScenarioStep.reservationName: const ScenarioPrompt(
      id: 'reservationName',
      text: "Can I have the name that's on the reservation?",
    ),
    ScenarioStep.numberPeople: const ScenarioPrompt(
      id: 'numberPeople',
      text: "How many people are in your party?",
    ),
    ScenarioStep.drinksOffer: const ScenarioPrompt(
      id: 'drinksOffer',
      text: "Here's the menu. Can I get you started with any drinks?",
    ),
    ScenarioStep.waterType: const ScenarioPrompt(
      id: 'waterType',
      text: "Still or sparkling?",
    ),
    ScenarioStep.iceQuestion: const ScenarioPrompt(
      id: 'iceQuestion',
      text: "Would you like ice with it?",
    ),
    ScenarioStep.readyToOrder: const ScenarioPrompt(
      id: 'readyToOrder',
      text: "Are you ready to order?",
    ),
    ScenarioStep.appetizers: const ScenarioPrompt(
      id: 'appetizers',
      text: "Would you like to order any appetizers?",
    ),
    ScenarioStep.entrees: const ScenarioPrompt(
      id: 'entrees',
      text: 'Would you like to order any entrees?',
    ),
    ScenarioStep.steakDoneness: const ScenarioPrompt(
      id: 'steakDoneness',
      text: "How would you like your steak?",
    ),
    ScenarioStep.sideChoice: const ScenarioPrompt(
      id: 'sideChoice',
      text: "Would you like salad or fries as your side?",
    ),
    ScenarioStep.isThatAll: const ScenarioPrompt(
      id: 'isThatAll',
      text: "Is that all for you?",
    ),
    ScenarioStep.howIsEverything: const ScenarioPrompt(
      id: 'howIsEverything',
      text: "how is everything?",
    ),
    ScenarioStep.areYouDone: const ScenarioPrompt(
      id: 'areYouDone',
      text: "Are you done with your food?",
    ),
    ScenarioStep.readyForBill: const ScenarioPrompt(
      id: 'readyForBill',
      text: "Are you ready for the bill?",
    ),
    ScenarioStep.paymentMethod: const ScenarioPrompt(
      id: 'paymentMethod',
      text: "How would you like to pay?",
    ),
    ScenarioStep.receipt: const ScenarioPrompt(
      id: 'receipt',
      text: "Would you like your receipt?",
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
      _currentMicrophoneState = MicrophoneState.idle;
      notifyListeners();
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
      _prompts[_currentStep]?.id,
      globalSearch: _globalSearchSteps.contains(_currentStep),
    );

    _currentMicrophoneState = MicrophoneState.idle;

    if (_currentStep != ScenarioStep.reservationName &&
        (classification == null || !classification.match)) {
      _systemMessage =
          "I'm not sure I understood. Could you try saying that another way?";
      notifyListeners();
      return;
    }

    _advanceScenario(classification?.intents ?? []);
    notifyListeners();
  }

  void _advanceScenario(List<String> intents) {
    if (!intents.contains('ready_no')) {
      _promptOverride = null;
      _promptPrefix = null;
      _systemMessage = null;
    }

    if (intents.contains('no_appetizer')) _wantsNoAppetizers = true;
    if (intents.contains('no_entrees')) _wantsNoEntrees = true;
    if (intents.contains('steak_doneness')) _hasAnsweredSteakDoneness = true;

    // new items are processed irrespective of step.. but it should matter that we're on the "ready to order" step
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
      case ScenarioStep.reservation:
        if (intents.contains("reservation_yes")) {
          _currentStep = ScenarioStep.reservationName;
        } else if (intents.contains("reservation_no")) {
          _currentStep = ScenarioStep.numberPeople;
        }
        break;
      case ScenarioStep.reservationName:
        _currentStep = ScenarioStep.numberPeople;
        break;
      case ScenarioStep.numberPeople:
        _currentStep = ScenarioStep.drinksOffer;
        break;
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
        } else if (intents.contains('ready_yes') ||
            orderedNewItems ||
            _wantsNoAppetizers ||
            _wantsNoEntrees) {
          _currentStep = _determineNextLogicalStep();
        }
        break;
      case ScenarioStep.appetizers:
        if (intents.contains('ask_specials') || intents.contains('ask_soup')) {
          _systemMessage =
              "Today's soup is creamy roasted garlic."; //TODO: append to message
        } else if (intents.contains('ask_recommendations')) {
          _systemMessage =
              "My personal favourite is the lobster pasta."; //TODO: append to message
        } else if (orderedNewItems || _wantsNoAppetizers || _wantsNoEntrees) {
          _currentStep = _determineNextLogicalStep();
        }
        break;
      case ScenarioStep.entrees:
        if (orderedNewItems || _wantsNoEntrees) {
          _currentStep = _determineNextLogicalStep();
        }
        break;
      case ScenarioStep.steakDoneness:
        if (intents.contains('steak_doneness')) {
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
      case ScenarioStep.howIsEverything:
        _currentStep = ScenarioStep.areYouDone;
        break;
      case ScenarioStep.areYouDone:
        if (intents.contains('done_eating_yes')) {
          _currentStep = ScenarioStep.readyForBill;
        } else if (intents.contains('done_eating_no')) {
          _promptOverride =
              "No problem, call me over when you're ready by saying 'I'm done'";
        }
        break;
      case ScenarioStep.readyForBill:
        if (intents.contains('ready_for_bill_yes')) {
          _currentStep = ScenarioStep.paymentMethod;
        } else if (intents.contains('ready_for_bill_no')) {
          _promptOverride =
              "No problem, call me over when you're ready by saying 'I'm ready for the bill'";
        }
        break;
      case ScenarioStep.paymentMethod:
        _currentStep = ScenarioStep.receipt;
        break;
      case ScenarioStep.receipt:
        _isScenarioComplete = true;
        _systemMessage = "Thank you for dining with us! Have a wonderful day.";
        break;
      case ScenarioStep.notReadyToOrder:
        break;
    }
    notifyListeners();
  }

  // --- Dynamic Routing Helper ---
  ScenarioStep _determineNextLogicalStep() {
    print("🛒 CURRENT ORDER ITEMS: $_orderItems");
    // 1. Steak Doneness Check (Highest priority if steak is ordered)
    if (_orderItems.contains('order_steak') && !_hasAnsweredSteakDoneness) {
      return ScenarioStep.steakDoneness;
    }

    bool hasEntree = _orderItems.any(
      (item) => ['order_steak', 'order_chicken', 'order_pasta'].contains(item),
    );
    bool hasSide = _orderItems.any(
      (item) => ['side_salad', 'side_fries'].contains(item),
    );
    bool hasAppetizer = _orderItems.any(
      (item) => ['order_soup', 'order_bruschetta'].contains(item),
    );

    if (_orderItems.contains('order_steak') && !hasSide) {
      return ScenarioStep.sideChoice;
    }

    if (!hasAppetizer &&
        !_wantsNoAppetizers &&
        (_currentStep == ScenarioStep.readyToOrder ||
            _currentStep == ScenarioStep.drinksOffer ||
            _currentStep == ScenarioStep.iceQuestion)) {
      return ScenarioStep.appetizers;
    }

    if (!hasEntree && !_wantsNoEntrees) {
      return ScenarioStep.entrees;
    }

    return ScenarioStep.isThatAll;
  }

  void resetScenario() {
    print("--- 🔄 RESETTING SCENARIO ---");

    // Reset core progression
    _currentStep = ScenarioStep.reservation;
    _isScenarioComplete = false;
    _orderItems.clear();

    // Reset Routing Flags
    _hasAnsweredSteakDoneness = false;
    _wantsNoAppetizers = false;
    _wantsNoEntrees = false;

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
