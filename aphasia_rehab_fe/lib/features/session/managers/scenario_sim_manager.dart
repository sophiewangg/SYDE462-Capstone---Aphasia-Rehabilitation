library scenario_sim_manager;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:aphasia_rehab_fe/features/dashboard/dashboard_page.dart';
import 'package:aphasia_rehab_fe/features/session/managers/dashboard_manager.dart';
import 'package:aphasia_rehab_fe/main.dart';
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

part 'scenario_sim_advance_states.dart';

enum ScenarioCurveball { none, wrongOrder, wrongReceipt, longWait }

class ScenarioSimManager extends ChangeNotifier {
  bool isInitialized = false;

  // --- Services ---
  final TranscriptionService _transcriptionService;
  final ScenarioApiService _scenarioApiService;
  final PromptService _promptService;
  final AudioPlayer _audioPlayer;
  final AudioPlayer _overridePlayer;
  final ElevenLabsService _elevenLabsService;
  final DashboardManager dashboardManager;
  final Random _random;
  final Future<void> Function(Duration) _delay;

  // --- State Variables: Transcription & Mic ---
  late final HintManager hintManager;
  StreamSubscription<TranscriptionResult>? _subscription;
  String _dontUnderstandUrl = "";
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

  // --- State Variables: Curveballs & Serving ---
  final List<ScenarioCurveball> _availableCurveballs = [
    ScenarioCurveball.none,
    ScenarioCurveball.wrongOrder,
    ScenarioCurveball.wrongReceipt,
  ];
  ScenarioCurveball _currentCurveball = ScenarioCurveball.none;
  final List<String> _servedItems = [];
  String? _orderedEntree;
  String? _wrongEntree;

  // Dynamic Routing Flags
  bool _hasAnsweredSteakDoneness = false;
  bool _wantsNoAppetizers = false;
  bool _wantsNoEntrees = false;

  // --- State Variables: Scenario Status ---
  bool _isBobEateryModalOpen = false;
  bool _isScenarioComplete = false;
  bool _showReceiptSheet = false;
  bool _showStaticReceiptSheet = false;
  bool _showRaiseHandButton = false;
  bool _showWaitTimer = false;
  int _simulatedWaitMinutes = 0;
  bool _showSystemMessage = false;
  bool _isDisposed = false;

  bool get isScenarioComplete => _isScenarioComplete;
  bool get showReceiptSheet => _showReceiptSheet;
  bool get showStaticReceiptSheet => _showStaticReceiptSheet;
  bool get showRaiseHandButton => _showRaiseHandButton;
  bool get showWaitTimer => _showWaitTimer;
  int get simulatedWaitMinutes => _simulatedWaitMinutes;
  bool get showSystemMessage => _showSystemMessage;

  // --- State Variables: Character and Audio ---
  String _currentCharacter = "";
  String _currentAudio = "";

  // --- State Variables: Food ---
  String? _appetizerUrl;
  String? _entreeUrl;

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
  List<String> get orderItems => List.unmodifiable(_orderItems);
  String? get appetizerUrl => _appetizerUrl;
  String? get entreeUrl => _entreeUrl;
  ScenarioCurveball get currentCurveball => _currentCurveball;
  bool get showReceipt => _showReceiptSheet || _showStaticReceiptSheet;

  List<ScenarioStep> get showAppetizer => [
    ScenarioStep.hereChicken,
    ScenarioStep.herePasta,
    ScenarioStep.hereSteak,
    ScenarioStep.howIsEverything,
    ScenarioStep.areYouDone,
    ScenarioStep.wrongOrderNudge,
    ScenarioStep.wrongOrderApology,
    ScenarioStep.wrongOrderResolvedPasta,
    ScenarioStep.wrongOrderResolvedChicken,
    ScenarioStep.wrongOrderResolvedSteak,
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

  final List<ScenarioStep> _globalSearchSteps = [
    ScenarioStep.drinksOffer,
    ScenarioStep.readyToOrder,
    ScenarioStep.appetizers,
    ScenarioStep.entrees,
    ScenarioStep.wrongOrderNudge,
  ];

  final List<ScenarioStep> _hereFood = [
    ScenarioStep.hereBruschetta,
    ScenarioStep.hereSoup,
    ScenarioStep.hereChicken,
    ScenarioStep.herePasta,
    ScenarioStep.hereSteak,
  ];

  ScenarioSimManager({
    TranscriptionService? transcriptionService,
    ScenarioApiService? scenarioApiService,
    PromptService? promptService,
    AudioPlayer? audioPlayer,
    AudioPlayer? overridePlayer,
    ElevenLabsService? elevenLabsService,
    DashboardManager? dashboardManager,
    Random? random,
    Future<void> Function(Duration)? delay,
  }) : _transcriptionService = transcriptionService ?? TranscriptionService(),
       _scenarioApiService = scenarioApiService ?? ScenarioApiService(),
       _promptService = promptService ?? PromptService(),
       _audioPlayer = audioPlayer ?? AudioPlayer(),
       _overridePlayer = overridePlayer ?? AudioPlayer(),
       _elevenLabsService = elevenLabsService ?? ElevenLabsService(),
       dashboardManager = dashboardManager ?? DashboardManager(),
       _random = random ?? Random(),
       _delay = delay ?? Future.delayed {
    hintManager = HintManager(
      dashboardManager: this.dashboardManager,
      getCurrentPrompt: () => currentPrompt!.promptText,
      getCurrentPromptSkill: () => currentPrompt!.skillPracticedId,
      getCurrentScenarioStep: () => currentStep,
      onPromptSimplified: (text, config) async {
        _promptOverride = text;
        notifyListeners();
        await _handlePromptOverride(config, false);
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
    _currentCurveball =
        _availableCurveballs[_random.nextInt(_availableCurveballs.length)];
    print("⚾ INITIAL CURVEBALL: ${_currentCurveball.name}");

    _currentPrompt = await _promptService.fetchPrompt(_currentStep);
    _currentCharacter = _currentPrompt!.imageSpeakingUrl;
    _currentAudio = _currentPrompt!.audioUrl;

    dashboardManager.addSkillPracticed(_currentPrompt!.skillPracticedId);

    _dontUnderstandUrl = await _promptService.getSignedUrl(
      'dont_understand.mp3',
      'speakeasy_voice_audios',
    );
    await precacheCharacterImage(config);
    playCharacterAudio(config, null);
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
    await _stopRecordingState();

    final transcript = _transcription.trim();
    _processDashboardMetrics(transcript);

    if (transcript.isEmpty) {
      _promptOverride = null;
      await _triggerFallback(
        "I didn't quite hear that. Could you try again? ",
        config,
        isPrefix: true,
      );
      return;
    }

    if (await _handleCurveballInterception(transcript, config)) return;

    final intents = await _classifyAndValidateTranscript(transcript, config);
    if (intents == null) return;

    await _advanceScenario(intents, config);
  }

  Future<void> _stopRecordingState() async {
    await _transcriptionService.stopStreaming();
    _isRecording = false;
    _currentMicrophoneState = MicrophoneState.processing;
    notifyListeners();
  }

  void _processDashboardMetrics(String transcript) {
    if (transcript.isEmpty) return;
    final wordsUsed = transcript.split(RegExp(r'\s+')).length;
    dashboardManager.incrementNumWordsUsed(wordsUsed);
    if (wordsUsed == 1) {
      dashboardManager.improveResponse(_currentPrompt!.promptText, transcript);
    }
  }

  Future<void> _triggerFallback(
    String message,
    ImageConfiguration config, {
    bool isPrefix = false,
  }) async {
    if (isPrefix) {
      _promptPrefix = message;
    } else {
      _promptOverride = message;
    }
    _transcription = "";
    notifyListeners();
    if (isPrefix) {
      await _handlePromptOverride(config, false);
    } else {
      await _handlePromptOverride(config, true);
    }
  }

  // --- Cleaned up Reusable Sequence ---
  Future<void> _executeCorrectionSequence(ImageConfiguration config) async {
    _currentCurveball = ScenarioCurveball.none;
    _entreeUrl = null;
    notifyListeners();

    _servedItems.remove(_wrongEntree);
    _servedItems.add(_orderedEntree!);

    // 1. Apologize
    await _handleScenarioStepChange(ScenarioStep.wrongOrderApology, config);
    await updateFoodVisuals(_servedItems, config);

    // DELAY: 5 Seconds before serving the actual food
    await _delay(const Duration(seconds: 5));

    // 2. Resolve (Show food and announce)
    if (_orderedEntree == 'order_pasta') {
      await _handleScenarioStepChange(
        ScenarioStep.wrongOrderResolvedPasta,
        config,
      );
    } else if (_orderedEntree == 'order_chicken') {
      await _handleScenarioStepChange(
        ScenarioStep.wrongOrderResolvedChicken,
        config,
      );
    } else {
      await _handleScenarioStepChange(
        ScenarioStep.wrongOrderResolvedSteak,
        config,
      );
    }

    // DELAY: 5 Seconds before asking "how is everything"
    await _delay(const Duration(seconds: 5));

    // 3. Move Forward
    _currentStep = ScenarioStep.howIsEverything;
    await _handleScenarioStepChange(_currentStep, config);
  }

  Future<bool> _handleCurveballInterception(
    String transcript,
    ImageConfiguration config,
  ) async {
    final currentItemBeingServed = _getServedItemForStep(_currentStep);

    if (currentItemBeingServed != null &&
        _currentCurveball == ScenarioCurveball.wrongOrder &&
        !_orderItems.contains(currentItemBeingServed)) {
      final correctionResult = await _scenarioApiService.verifyOrderCorrection(
        transcript,
        _orderItems,
        _servedItems,
      );
      _transcription = "";
      if (correctionResult != null) {
        if (correctionResult.isCorrected) {
          print("✅ Curveball successfully navigated (Immediate)!");
          await _executeCorrectionSequence(config);
          return true;
        } else {
          print("⚠️ Curveball Nudge triggered!");
          _currentStep = ScenarioStep.wrongOrderNudge;
          await _handleScenarioStepChange(_currentStep, config);
          return true;
        }
      }
    }
    return false;
  }

  String? _getServedItemForStep(ScenarioStep step) {
    switch (step) {
      case ScenarioStep.hereBruschetta:
        return 'order_bruschetta';
      case ScenarioStep.hereSoup:
        return 'order_soup';
      case ScenarioStep.herePasta:
        return 'order_pasta';
      case ScenarioStep.hereChicken:
        return 'order_chicken';
      case ScenarioStep.hereSteak:
        return 'order_steak';
      default:
        return null;
    }
  }

  Future<List<String>?> _classifyAndValidateTranscript(
    String transcript,
    ImageConfiguration config,
  ) async {
    final classification = await _scenarioApiService.classifyUtterance(
      transcript,
      _currentStep.id,
      globalSearch: _globalSearchSteps.contains(_currentStep),
    );
    _transcription = "";

    if (_currentStep != ScenarioStep.reservationName &&
        _currentStep != ScenarioStep.beBackShortly &&
        _currentStep != ScenarioStep.howHelp &&
        _currentStep != ScenarioStep.checkOrder &&
        _currentStep != ScenarioStep.checkReceipt &&
        _currentStep != ScenarioStep.resolveReceipt &&
        !_hereFood.contains(_currentStep) &&
        (classification == null || !classification.match)) {
      final List<String>? intents = await _performLLMFallback(transcript);

      if (intents == null) {
        dashboardManager.incrementNumUnclearResponses();
        await _triggerFallback(
          "I'm not sure I understood. Could you try saying that another way?",
          config,
        );
        return null;
      }
      return intents;
    }
    return classification?.intents ?? [];
  }

  Future<List<String>?> _performLLMFallback(String transcript) async {
    final intents = await _scenarioApiService.llmFallback(
      transcript,
      _currentStep.id,
      _currentPrompt!.promptText,
    );
    return intents;
  }

  Future<void> updateFoodVisuals(
    List<String> items,
    ImageConfiguration config,
  ) async {
    _entreeUrl = null;

    if (_appetizerUrl == null) {
      if (items.contains('order_bruschetta')) {
        _appetizerUrl = await _promptService.getSignedUrl(
          'bruschetta.png',
          'speakeasy_food_images',
        );
      } else if (items.contains('order_soup')) {
        _appetizerUrl = await _promptService.getSignedUrl(
          'soup.png',
          'speakeasy_food_images',
        );
      }
    }

    if (items.contains('order_pasta')) {
      _entreeUrl = await _promptService.getSignedUrl(
        'pasta.png',
        'speakeasy_food_images',
      );
    } else if (items.contains('order_chicken')) {
      _entreeUrl = await _promptService.getSignedUrl(
        'chicken.png',
        'speakeasy_food_images',
      );
    } else if (items.contains('order_steak')) {
      _entreeUrl = await _promptService.getSignedUrl(
        'steak.png',
        'speakeasy_food_images',
      );
    }

    if (_appetizerUrl != null) await precacheFood(_appetizerUrl!, config);
    if (_entreeUrl != null) await precacheFood(_entreeUrl!, config);
  }

  void navigateToDashboardPage() {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  Future<void> handleEndOfSession() async {
    print("--- 🛑 ENDING SESSION ---");
    await _transcriptionService.stopStreaming();
    _isRecording = false;
    _currentMicrophoneState = MicrophoneState.idle;
    _transcription = "";
    resetScenario();
    notifyListeners();
  }

  /// Called when user leaves session screen via back navigation.
  /// Keeps scenario progress intact so they can resume later.
  Future<void> handlePauseSession() async {
    if (_isRecording) {
      await _transcriptionService.stopStreaming();
      _isRecording = false;
    }
    _currentMicrophoneState = MicrophoneState.idle;
    _transcription = "";
    notifyListeners();
  }

  Future<void> _handleScenarioStepChange(
    ScenarioStep newStep,
    ImageConfiguration config,
  ) async {
    _promptOverride = null;
    _promptPrefix = null;

    if (newStep == ScenarioStep.receipt) {
      _isScenarioComplete = true;
    }

    Prompt nextPrompt = await _promptService.fetchPrompt(newStep);
    _currentPrompt = nextPrompt;
    _currentCharacter = nextPrompt.imageSpeakingUrl;
    _currentAudio = nextPrompt.audioUrl;
    dashboardManager.addSkillPracticed(_currentPrompt!.skillPracticedId);
    dashboardManager.incrementNumPromptsGiven();

    _isRecording = false;

    await precacheCharacterImage(config);
    playCharacterAudio(config, null);
    _currentMicrophoneState = MicrophoneState.idle;

    notifyListeners();
  }

  Future<void> _advanceScenario(
    List<String> intents,
    ImageConfiguration config,
  ) async {
    if (intents.contains('no_appetizer')) _wantsNoAppetizers = true;
    if (intents.contains('no_entrees')) _wantsNoEntrees = true;
    if (intents.contains('steak_doneness')) _hasAnsweredSteakDoneness = true;

    bool orderedNewItems = false;
    for (String intent in intents) {
      if (intent.startsWith('order_') || intent.startsWith('side_')) {
        if (!_orderItems.contains(intent)) {
          _orderItems.add(intent);
          orderedNewItems = true;
        }
      }
    }

    await _scenarioSimAdvanceStateFor(
      _currentStep,
    ).advance(this, intents, orderedNewItems, config);
  }

  ScenarioStep _determineNextLogicalStep() {
    print("🛒 CURRENT ORDER ITEMS: $_orderItems");
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

    _currentStep = ScenarioStep.reservation;
    _isScenarioComplete = false;
    _showReceiptSheet = false;
    _showStaticReceiptSheet = false;
    _showRaiseHandButton = false;

    _orderItems.clear();
    _servedItems.clear();

    _currentCurveball =
        _availableCurveballs[_random.nextInt(_availableCurveballs.length)];

    _hasAnsweredSteakDoneness = false;
    _wantsNoAppetizers = false;
    _wantsNoEntrees = false;

    _transcription = "";
    _promptPrefix = null;
    _promptOverride = null;

    _currentCharacter = "";
    _currentAudio = "";

    _appetizerUrl = null;
    _entreeUrl = null;

    _isBobEateryModalOpen = false;

    hintManager.reset();
    dashboardManager.resetDashboard();

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
      final provider = NetworkImage(_currentCharacter);
      final ImageStream stream = provider.resolve(config);
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

    if (_isDisposed) return;
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
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> _handlePromptOverride(
    ImageConfiguration config,
    bool isDontUnderstand,
  ) async {
    if (!_isScenarioComplete) {
      dashboardManager.incrementNumRepeats();
    }
    _currentCharacter = _currentPrompt!.imageSpeakingUrl;
    await precacheCharacterImage(config);
    await clearAudioCache();
    notifyListeners();
    if (isDontUnderstand) {
      playCharacterAudio(config, _dontUnderstandUrl);
    } else {
      await playElevenLabsAudio(currentDialogue, 'override-prompt');
    }
    _currentMicrophoneState = MicrophoneState.idle;
    _currentCharacter = currentPrompt!.imageListeningUrl;
    await precacheCharacterImage(config);
    notifyListeners();
  }

  Future<void> playCharacterAudio(
    ImageConfiguration config,
    String? overrideUrl,
  ) async {
    if (_currentAudio.isNotEmpty) {
      try {
        if (overrideUrl != null) {
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.parse(_dontUnderstandUrl)),
            preload: true,
          );
        } else {
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.parse(_currentAudio)),
            preload: true,
          );
        }
      } catch (e) {
        print("Error loading audio: $e");
      }
    }
    await _audioPlayer.play();

    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.pause();

    _currentCharacter = currentPrompt!.imageListeningUrl;
    await precacheCharacterImage(config);
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> playElevenLabsAudio(String text, String promptId) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/audio_$promptId.mp3';
    final file = File(filePath);

    if (await file.exists()) {
      print("Playing from local cache: $filePath");
      await _overridePlayer.setFilePath(filePath);
    } else {
      print("Fetching from ElevenLabs API...");
      Uint8List audioBytes = await _elevenLabsService.fetchAudio(text);
      await file.writeAsBytes(audioBytes);
      await _overridePlayer.setFilePath(filePath);
    }

    // Start playing
    await _overridePlayer.play();

    // 1. Wait for the audio to actually finish
    // We listen to the processingState stream and wait for the 'completed' event
    await _overridePlayer.processingStateStream.firstWhere(
      (state) => state == ProcessingState.completed,
    );

    // 2. Optional: Reset the player position so it's ready for next time
    await _overridePlayer.stop();
  }

  Future<void> clearAudioCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync();

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

  void toggleBobEateryModal() {
    _isBobEateryModalOpen = !_isBobEateryModalOpen;
    notifyListeners();
  }

  void resetTranscription() {
    _transcription = '';
    notifyListeners();
  }

  Future<void> raiseHandPressed(ImageConfiguration config) async {
    print("✋ Raise Hand Button Pressed! Bypassing backend.");

    // 1. Hide the wait UI
    _showSystemMessage = false;
    _showRaiseHandButton = false;
    _showWaitTimer = false;

    // 2. Force the mic to stop and reset to idle, just in case they tried to speak
    if (_isRecording) {
      await _transcriptionService.stopStreaming();
      _isRecording = false;
    }
    _currentMicrophoneState = MicrophoneState.idle;

    // 3. Immediately jump to howHelp and update the UI/AI
    _currentStep = ScenarioStep.howHelp;
    await _handleScenarioStepChange(_currentStep, config);

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    hintManager.dispose();
    _audioPlayer.dispose();
    _overridePlayer.dispose();
    super.dispose();
  }
}
