import 'dart:io';
import 'dart:typed_data';

import 'package:aphasia_rehab_fe/features/session/managers/dashboard_manager.dart';
import 'package:aphasia_rehab_fe/models/prompt_model.dart';
import 'package:aphasia_rehab_fe/models/scenario_step.dart';
import 'package:aphasia_rehab_fe/services/eleven_labs_service.dart';
import 'package:aphasia_rehab_fe/services/prompt_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import '../../../api_service.dart';
import '../../../services/transcription_service.dart';
import '../../../models/microphone_state.dart';
import 'hint_manager.dart';

class ScenarioSimManager extends ChangeNotifier {
  bool isInitialized = false;

  // --- Services ---
  final TranscriptionService _transcriptionService = TranscriptionService();
  final ScenarioApiService _scenarioApiService = ScenarioApiService();
  final PromptService _promptService = PromptService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _overridePlayer = AudioPlayer();

  final ElevenLabsService _elevenLabsService = ElevenLabsService();

  // --- State Variables: Transcription & Mic ---
  late final HintManager hintManager;
  final DashboardManager dashboardManager = DashboardManager();
  StreamSubscription<TranscriptionResult>? _subscription;
  String _transcription = "";
  bool _hasPermission = false;
  bool _isRecording = false;
  MicrophoneState _currentMicrophoneState = MicrophoneState.idle;

  // --- State Variables: Scenario Progression ---
  ScenarioStep _currentStep = ScenarioStep.reservation;
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
  bool _showReceiptSheet = false;

  bool get isScenarioComplete => _isScenarioComplete;
  bool get showReceiptSheet => _showReceiptSheet;

  // --- State Variables: Character and Audio ---
  String _currentCharacter = "";
  String _currentAudio = "";

  // --- State Variables: Food ---
  String? _appetizerUrl = null;
  String? _entreeUrl = null;

  // --- Getters ---
  String get transcription => _transcription;
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  MicrophoneState get currentMicrophoneState => _currentMicrophoneState;
  bool get isBobEateryModalOpen => _isBobEateryModalOpen;
  Prompt? get currentPrompt => _currentPrompt;
  String get currentCharacter => _currentCharacter;
  String? get promptOverride => _promptOverride;
  String? get promptPrefix => _promptPrefix;
  ScenarioStep get currentStep => _currentStep;
  String? get appetizerUrl => _appetizerUrl;
  String? get entreeUrl => _entreeUrl;
  List<ScenarioStep> get showAppetizer => [
    ScenarioStep.hereChicken,
    ScenarioStep.herePasta,
    ScenarioStep.hereSteak,
    ScenarioStep.howIsEverything,
    ScenarioStep.areYouDone,
  ];
  List<ScenarioStep> get showEntree => [
    ScenarioStep.howIsEverything,
    ScenarioStep.areYouDone,
  ];

  String get currentDialogue {
    final base = _currentPrompt!.promptText;
    if (_promptOverride != null) return _promptOverride!;
    if (_promptPrefix != null) return "${_promptPrefix!}$base";
    return base;
  }

  // Define which steps should allow the user to order anything from the menu
  final List<ScenarioStep> _globalSearchSteps = [
    ScenarioStep.drinksOffer,
    ScenarioStep.readyToOrder,
    ScenarioStep.appetizers,
    ScenarioStep.entrees,
  ];

  final List<ScenarioStep> _hereFood = [
    ScenarioStep.hereBruschetta,
    ScenarioStep.hereSoup,
    ScenarioStep.hereChicken,
    ScenarioStep.herePasta,
    ScenarioStep.hereSteak,
  ];

  ScenarioSimManager() {
    hintManager = HintManager(
      dashboardManager: dashboardManager,
      getCurrentPrompt: () => currentPrompt!.promptText,
      onPromptSimplified: (text, config) async {
        _promptOverride = text;
        notifyListeners();
        await _handlePromptOverride(config);
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

    dashboardManager.addSkillPracticed(_currentPrompt!.skillPracticedId);

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
      if (hintManager.isModalOpen) {
        processHint(config);
        return;
      }
      handleEndOfTurn(config);
    } else {
      startRecording();
    }
  }

  void processHint(ImageConfiguration config) async {
    dashboardManager.incrementHintUsed(_currentPrompt!.skillPracticedId);
    await _transcriptionService.stopStreaming();
    _isRecording = false;
    _currentMicrophoneState = MicrophoneState.processing;
    hintManager.onTranscriptReceived(_transcription, config);
    notifyListeners();
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

    final wordsUsed = transcript.split(RegExp(r'\s+')).length;
    dashboardManager.incrementNumWordsUsed(wordsUsed);
    if (wordsUsed == 1) {
      dashboardManager.improveResponse(
        _currentPrompt!.promptText,
        transcription,
      );
    }

    if (transcript.isEmpty) {
      _promptPrefix = "I didn't quite hear that. Could you try again? ";
      notifyListeners();
      await _handlePromptOverride(config);
      return;
    }

    final classification = await _scenarioApiService.classifyUtterance(
      transcript,
      _currentStep.id,
      globalSearch: _globalSearchSteps.contains(_currentStep),
    );
    _transcription = "";

    if (_currentStep != ScenarioStep.reservationName &&
        !_hereFood.contains(_currentStep) &&
        (classification == null || !classification.match)) {
      _promptOverride =
          "I'm not sure I understood. Could you try saying that another way?";
      notifyListeners();
      dashboardManager.incrementNumUnclearResponses();
      await _handlePromptOverride(config);
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

  Future<void> _handleScenarioStepChange(
    ScenarioStep newStep,
    ImageConfiguration config, // Pass the config you captured from context
  ) async {
    _promptOverride = null;
    _promptPrefix = null;
    Prompt nextPrompt = await _promptService.fetchPrompt(newStep);
    _currentPrompt = nextPrompt;
    _currentCharacter = nextPrompt.imageSpeakingUrl;
    _currentAudio = nextPrompt.audioUrl;
    dashboardManager.addSkillPracticed(_currentPrompt!.skillPracticedId);
    dashboardManager.incrementNumPromptsGiven();

    _isRecording = false;

    await precacheCharacterImage(config);

    playCharacterAudio(config);

    _currentMicrophoneState = MicrophoneState.idle;

    notifyListeners();
  }

  void _advanceScenario(List<String> intents, ImageConfiguration config) async {
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
          await _handleScenarioStepChange(_currentStep, config);
        } else if (intents.contains("reservation_no")) {
          _currentStep = ScenarioStep.numberPeople;
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.reservationName:
        _currentStep = ScenarioStep.numberPeople;
        await _handleScenarioStepChange(_currentStep, config);
        break;
      case ScenarioStep.numberPeople:
        _currentStep = ScenarioStep.drinksOffer;
        await _handleScenarioStepChange(_currentStep, config);
        break;
      case ScenarioStep.drinksOffer:
        if (intents.contains('beverage_water')) {
          _currentStep = ScenarioStep.waterType;
          await _handleScenarioStepChange(_currentStep, config);
        } else if (intents.contains('water_still') ||
            intents.contains('water_sparkling') ||
            intents.contains('beverage_other')) {
          _currentStep = ScenarioStep.iceQuestion;
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.waterType:
        if (intents.contains('water_still') ||
            intents.contains('water_sparkling')) {
          _currentStep = ScenarioStep.iceQuestion;
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.iceQuestion:
        _currentStep = ScenarioStep.readyToOrder;
        await _handleScenarioStepChange(_currentStep, config);

        break;
      case ScenarioStep.readyToOrder:
        if (intents.contains('ready_no')) {
          _promptOverride =
              "No problem, just say 'I'm ready to order' when you've decided.";
          notifyListeners();
          await _handlePromptOverride(config);
        } else if (intents.contains('ready_yes') ||
            orderedNewItems ||
            _wantsNoAppetizers ||
            _wantsNoEntrees) {
          _currentStep = _determineNextLogicalStep();
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.appetizers:
        if (intents.contains('ask_specials') || intents.contains('ask_soup')) {
          _promptOverride = "Today's soup is creamy roasted garlic.";
          notifyListeners();
          await _handlePromptOverride(config);
        } else if (intents.contains('ask_recommendations')) {
          _promptOverride =
              "My personal favourite is the lobster pasta."; //TODO: append to message
          notifyListeners();
          await _handlePromptOverride(config);
        } else if (orderedNewItems || _wantsNoAppetizers || _wantsNoEntrees) {
          _currentStep = _determineNextLogicalStep();
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.entrees:
        if (orderedNewItems || _wantsNoEntrees) {
          _currentStep = _determineNextLogicalStep();
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.steakDoneness:
        if (intents.contains('steak_doneness')) {
          _currentStep = _determineNextLogicalStep();
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.sideChoice:
        if (orderedNewItems) {
          _currentStep = _determineNextLogicalStep();
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.isThatAll:
        if (intents.contains('is_that_all_yes')) {
          if (_orderItems.contains('order_bruschetta')) {
            _appetizerUrl = await _promptService.getSignedUrl(
              'bruschetta.png',
              'speakeasy_food_images',
            );
            _currentStep = ScenarioStep.hereBruschetta;
          } else if (_orderItems.contains('order_soup')) {
            _appetizerUrl = await _promptService.getSignedUrl(
              'soup.png',
              'speakeasy_food_images',
            );
            _currentStep = ScenarioStep.hereSoup;
          }

          if (_orderItems.contains('order_pasta')) {
            _entreeUrl = await _promptService.getSignedUrl(
              'pasta.png',
              'speakeasy_food_images',
            );
            if (_currentStep != ScenarioStep.hereBruschetta &&
                _currentStep != ScenarioStep.hereSoup) {
              _currentStep = ScenarioStep.herePasta;
            }
          } else if (_orderItems.contains('order_chicken')) {
            _entreeUrl = await _promptService.getSignedUrl(
              'chicken.png',
              'speakeasy_food_images',
            );
            if (_currentStep != ScenarioStep.hereBruschetta &&
                _currentStep != ScenarioStep.hereSoup) {
              _currentStep = ScenarioStep.hereChicken;
            }
          } else if (_orderItems.contains('order_steak')) {
            _entreeUrl = await _promptService.getSignedUrl(
              'steak.png',
              'speakeasy_food_images',
            );
            if (_currentStep != ScenarioStep.hereBruschetta &&
                _currentStep != ScenarioStep.hereSoup) {
              _currentStep = ScenarioStep.hereSteak;
            }
          }
          // _currentStep = ScenarioStep.howIsEverything;
          await _handleScenarioStepChange(_currentStep, config);
        } else if (intents.contains('is_that_all_no')) {
          _currentStep = ScenarioStep.appetizers; // Loop back
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;
      case ScenarioStep.hereBruschetta || ScenarioStep.hereSoup:
        if (_orderItems.contains('order_pasta')) {
          _currentStep = ScenarioStep.herePasta;
        } else if (_orderItems.contains('order_chicken')) {
          _currentStep = ScenarioStep.hereChicken;
        } else if (_orderItems.contains('order_steak')) {
          _currentStep = ScenarioStep.hereSteak;
        } else {
          _currentStep = ScenarioStep.howIsEverything;
        }
        await precacheFood(_appetizerUrl!, config);
        await _handleScenarioStepChange(_currentStep, config);
      case ScenarioStep.herePasta ||
          ScenarioStep.hereChicken ||
          ScenarioStep.hereSteak:
        await precacheFood(entreeUrl!, config);
        _currentStep = ScenarioStep.howIsEverything;
        await _handleScenarioStepChange(_currentStep, config);
      case ScenarioStep.howIsEverything:
        _currentStep = ScenarioStep.areYouDone;
        await _handleScenarioStepChange(_currentStep, config);
        break;
      case ScenarioStep.areYouDone:
        if (intents.contains('done_eating_yes')) {
          _currentStep = ScenarioStep.readyForBill;
          await _handleScenarioStepChange(_currentStep, config);
        } else if (intents.contains('done_eating_no')) {
          _promptOverride =
              "No problem, call me over when you're ready by saying 'I'm done'";
          notifyListeners();
          await _handlePromptOverride(config);
        }
        break;
      case ScenarioStep.readyForBill:
        if (intents.contains('ready_for_bill_yes')) {
          _showReceiptSheet = true;
          _currentStep = ScenarioStep.paymentMethod;
          await _handleScenarioStepChange(_currentStep, config);
          notifyListeners();
        } else if (intents.contains('ready_for_bill_no')) {
          _promptOverride =
              "No problem, call me over when you're ready by saying 'I'm ready for the bill'";
          notifyListeners();
          await _handlePromptOverride(config);
        }
        break;
      case ScenarioStep.paymentMethod:
        _showReceiptSheet = false;
        _currentStep = ScenarioStep.receipt;
        await _handleScenarioStepChange(_currentStep, config);
        notifyListeners();
        break;
      case ScenarioStep.receipt:
        _isScenarioComplete = true;
        _promptOverride = "Thank you for dining with us! Have a wonderful day.";
        _currentCharacter = _currentPrompt!.imageSpeakingUrl;
        notifyListeners();
        await _handlePromptOverride(config);
        break;
      case ScenarioStep.notReadyToOrder:
        break;
    }
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
    _showReceiptSheet = false;
    _orderItems.clear();

    // Reset Routing Flags
    _hasAnsweredSteakDoneness = false;
    _wantsNoAppetizers = false;
    _wantsNoEntrees = false;

    // Reset text states
    _transcription = "";
    _promptPrefix = null;
    _promptOverride = null;

    // Reset Character/Audio/Food states
    _currentCharacter = "";
    _currentAudio = "";

    // --- State Variables: Food ---
    _appetizerUrl = null;
    _entreeUrl = null;

    hintManager.reset();
    dashboardManager.resetDashboard();

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

  Future<void> precacheFood(String url, ImageConfiguration config) async {
    final provider = NetworkImage(url);
    final ImageStream stream = provider.resolve(config);
    final Completer<void> completer = Completer<void>();
    final listener = ImageStreamListener(
      (ImageInfo info, bool sync) => completer.complete(),
      onError: (dynamic exc, StackTrace? stack) => completer.completeError(exc),
    );

    stream.addListener(listener);
    await completer.future;
    stream.removeListener(listener);
    notifyListeners();
  }

  Future<void> _handlePromptOverride(ImageConfiguration config) async {
    _currentCharacter = _currentPrompt!.imageSpeakingUrl;
    await precacheCharacterImage(config);
    await clearAudioCache();
    notifyListeners();
    await playElevenLabsAudio(currentDialogue, 'override-prompt');
    _currentMicrophoneState = MicrophoneState.idle;
    _currentCharacter = currentPrompt!.imageListeningUrl;
    await precacheCharacterImage(config);
    notifyListeners();
  }

  Future<void> playCharacterAudio(ImageConfiguration config) async {
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

  Future<void> playElevenLabsAudio(String text, String promptId) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/audio_$promptId.mp3';
    final file = File(filePath);

    if (await file.exists()) {
      // 1. Play from Cache
      print("Playing from local cache: $filePath");
      await _overridePlayer.setFilePath(filePath);
    } else {
      // 2. Fetch from ElevenLabs API
      print("Fetching from ElevenLabs API...");
      Uint8List audioBytes = await _elevenLabsService.fetchAudio(text);

      // 3. Save to Cache
      await file.writeAsBytes(audioBytes);

      await _overridePlayer.setFilePath(filePath);
    }

    await _overridePlayer.play();
  }

  Future<void> clearAudioCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      // 1. List all files in the documents directory
      final List<FileSystemEntity> files = directory.listSync();

      // 2. Filter for only your audio cache files
      for (var file in files) {
        if (file is File && file.path.contains('audio_')) {
          await file.delete();
          print("Deleted cached audio: ${file.path}");
        }
      }
      print("Audio cache cleared successfully.");
    } catch (e) {
      print("Error clearing cache: $e");
    }
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
    _overridePlayer.dispose();
    super.dispose();
  }
}
