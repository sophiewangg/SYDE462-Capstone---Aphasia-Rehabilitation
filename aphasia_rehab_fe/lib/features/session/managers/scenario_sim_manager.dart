import 'package:aphasia_rehab_fe/models/prompt_model.dart';
import 'package:aphasia_rehab_fe/models/scenario_step.dart';
import 'package:aphasia_rehab_fe/services/prompt_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
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
  bool isInitialized = false;
  final String _dontUnderstandFilename = "dont_understand.mp3";
  final String _didntHearFilename = "didnt_hear.mp3";

  String _dontUnderstandUrl = "";
  String _didntHearUrl = "";
  // --- Services ---
  final TranscriptionService _transcriptionService = TranscriptionService();
  final ScenarioApiService _scenarioApiService = ScenarioApiService();
  final PromptService _promptService = PromptService();
  final CueService _cueService = CueService();
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
  ScenarioStep _currentStep = ScenarioStep.drinksOffer;
  String? _promptPrefix;
  String? _promptOverride;
  final List<String> _orderItems = [];
  Prompt? _currentPrompt;

  // Dynamic Routing Flags
  bool _hasAnsweredSteakDoneness = false;
  bool _wantsNoAppetizers = false;
  bool _wantsNoEntrees = false;

  // --- State Variables: Scenario Status ---
  bool _isBobEateryModalOpen = false;
  bool _isScenarioComplete = false;

  bool get isScenarioComplete => _isScenarioComplete;

  // --- State Variables: Character and Audio ---
  String _currentCharacter = "";
  String _currentAudio = "";

  // --- Getters ---
  String get transcription => _transcription;
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  MicrophoneState get currentMicrophoneState => _currentMicrophoneState;
  bool get isBobEateryModalOpen => _isBobEateryModalOpen;
  Prompt? get currentPrompt => _currentPrompt;
  String get currentCharacter => _currentCharacter;

  String get currentDialogue {
    final base = _currentPrompt!.promptText;
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
  }

  // --- Core Scenario Flow Logic ---
  Future<void> init(ImageConfiguration config) async {
    // 1. Fetch the data from FastAPI (as you already do)
    _currentPrompt = await _promptService.fetchPrompt(_currentStep);
    _currentCharacter = _currentPrompt!.imageSpeakingUrl;
    _currentAudio = _currentPrompt!.audioUrl;

    _dontUnderstandUrl = await _promptService.getSignedUrl(
      _dontUnderstandFilename,
    );
    _didntHearUrl = await _promptService.getSignedUrl(_didntHearFilename);

    // 2. Pre-cache the image immediately after getting the URL
    await precacheCharacterImage(config);

    playCharacterAudio(config);
    isInitialized = true;
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

  void handleMicToggle(ImageConfiguration config) {
    if (_isRecording) {
      if (_isModalOpen) {
        handleEndOfCue();
      } else {
        handleEndOfTurn(config);
      }
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

  Future<void> handleEndOfTurn(ImageConfiguration config) async {
    print("--- 🛑 END OF TURN ---");
    await _transcriptionService.stopStreaming();
    _isRecording = false;
    _currentMicrophoneState = MicrophoneState.processing;
    notifyListeners();
    final transcript = _transcription.trim();

    if (transcript.isEmpty) {
      _promptPrefix = "I didn't quite hear that. Could you try again? ";
      _currentAudio = _didntHearUrl;
      _currentCharacter = _currentPrompt!.imageSpeakingUrl;
      await precacheCharacterImage(config);
      playCharacterAudio(config);
      _currentMicrophoneState = MicrophoneState.idle;
      notifyListeners();
      return;
    }

    final classification = await _scenarioApiService.classifyUtterance(
      transcript,
      _prompts[_currentStep]?.id,
      globalSearch: _globalSearchSteps.contains(_currentStep),
    );
    _transcription = "";

    if (_currentStep != ScenarioStep.reservationName &&
        (classification == null || !classification.match)) {
      _promptOverride =
          "I'm not sure I understood. Could you try saying that another way?";
      _currentAudio = _dontUnderstandUrl;
      _currentCharacter = _currentPrompt!.imageConfusedUrl;
      await precacheCharacterImage(config);
      playCharacterAudio(config);
      _currentMicrophoneState = MicrophoneState.idle;
      notifyListeners();
      return;
    }

    _advanceScenario(classification?.intents ?? [], config);
  }

  Future<void> handleEndOfSession() async {
    print("--- 🛑 ENDING SESSION ---");
    await _transcriptionService.stopStreaming();
    _isRecording = false;
    _currentMicrophoneState = MicrophoneState.idle;
    _transcription = "";
    notifyListeners();
  }

  Future<void> handleEndOfCue() async {
    print("--- 🛑 PROCESSING CUE ---");
    await _transcriptionService.stopStreaming();
    hintManager.onTranscriptReceived(_transcription);
    _isRecording = false;
    _transcription = "";
    }

  Future<void> _handleScenarioStepChange(
    ScenarioStep newStep,
    ImageConfiguration config, // Pass the config you captured from context
  ) async {
    Prompt nextPrompt = await _promptService.fetchPrompt(newStep);
    _currentPrompt = nextPrompt;
    _currentCharacter = nextPrompt.imageSpeakingUrl;
    _currentAudio = nextPrompt.audioUrl;

    _isRecording = false;

    await precacheCharacterImage(config);

    playCharacterAudio(config);

    _currentMicrophoneState = MicrophoneState.idle;

    notifyListeners();
  }

  void _advanceScenario(String? intent, ImageConfiguration config) {
    if (intent != 'ready_no') {
      _promptOverride = null;
      _promptPrefix = null;
    }
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
          _handleScenarioStepChange(_currentStep, config);
        } else if (intent == 'water_still' ||
            intent == 'water_sparkling' ||
            intent == 'beverage_other') {
          _currentStep = ScenarioStep.iceQuestion;
          _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.waterType:
        if (intents.contains('water_still') ||
            intents.contains('water_sparkling')) {
          _currentStep = ScenarioStep.iceQuestion;
          _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.iceQuestion:
        _currentStep = ScenarioStep.readyToOrder;
        _handleScenarioStepChange(_currentStep, config);

        break;
      case ScenarioStep.readyToOrder:
        if (intent == 'ready_yes') {
          _promptOverride = null;
          _currentStep = ScenarioStep.appetizers;
          _handleScenarioStepChange(_currentStep, config);
        } else if (intent == 'ready_no') {
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
        if (intent == 'ask_specials' || intent == 'ask_soup') {
          _promptOverride = "Today's soup is creamy roasted garlic.";
        } else if (intent == 'ask_recommendations') {
          _promptOverride = "My personal favourite is the lobster pasta.";
        } else if (intent == 'order_steak') {
          _currentStep = ScenarioStep.steakDoneness;
          _handleScenarioStepChange(_currentStep, config);
        } else if (intent == 'order_chicken' || intent == 'order_pasta') {
          _orderItems.add(intent!);
          _currentStep = ScenarioStep.isThatAll;
          _handleScenarioStepChange(_currentStep, config);
        } else if (intent == 'order_soup' || intent == 'order_bruschetta') {
          //TODO: there was another app
          _orderItems.add(intent!);
          _currentStep = ScenarioStep.entrees;
          _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.entrees:
        if (intent == 'order_steak') {
          _currentStep = ScenarioStep.steakDoneness;
          _handleScenarioStepChange(_currentStep, config);
        } else if (intent == 'order_chicken' || intent == 'order_pasta') {
          _orderItems.add(intent!);
          _currentStep = ScenarioStep.isThatAll;
          _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.steakDoneness:
        if (intent == 'steak_doneness') {
          _currentStep = ScenarioStep.sideChoice;
          _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.sideChoice:
        if (intent == 'side_salad' || intent == 'side_fries') {
          _orderItems.add(intent!);
          _currentStep = ScenarioStep.isThatAll;
          _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.isThatAll:
        if (intent == 'is_that_all_yes') {
          _currentStep = ScenarioStep.allergies;
          _handleScenarioStepChange(_currentStep, config);
        } else if (intent == 'is_that_all_no') {
          _currentStep = ScenarioStep.appetizers;
          _handleScenarioStepChange(_currentStep, config);
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
  Future<void> precacheCharacterImage(ImageConfiguration config) async {
    if (_currentCharacter.isNotEmpty) {
      // This is the manual version of precacheImage
      final provider = NetworkImage(_currentCharacter);

      // Resolve the image using the config we passed in.
      // This triggers the download and caching.
      final ImageStream stream = provider.resolve(config);

      // Optional: If you MUST wait for it to finish loading before moving on
      final Completer<void> completer = Completer<void>();
      final listener = ImageStreamListener(
        (ImageInfo info, bool sync) => completer.complete(),
        onError: (dynamic exc, StackTrace? stack) =>
            completer.completeError(exc),
      );

      stream.addListener(listener);
      await completer.future;
      stream.removeListener(listener);
    }
    notifyListeners();
  }

  void playCharacterAudio(ImageConfiguration config) async {
    if (_currentAudio.isNotEmpty) {
      try {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(_currentAudio)),
          preload: true,
        );
      } catch (e) {
        print("Error loading audio: $e");
      }
    }
    await _audioPlayer.play();

    // Important: After it finishes, you usually want to seek back to the start
    // so the user can play it again if they want.
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.pause();

    _currentCharacter = currentPrompt!.imageListeningUrl;
    await precacheCharacterImage(config);
    notifyListeners();
  }

  // --- Utilities ---

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
