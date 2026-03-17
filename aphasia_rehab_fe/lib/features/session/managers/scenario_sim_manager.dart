import 'dart:io';
import 'dart:math';
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

enum ScenarioCurveball { none, wrongOrder, wrongReceipt, longWait }

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
  ScenarioStep _currentStep = ScenarioStep.isThatAll;
  String? _promptPrefix;
  String? _promptOverride;
  final List<String> _orderItems = ['order_steak'];
  Prompt? _currentPrompt;

  // --- State Variables: Curveballs & Serving ---
  final List<ScenarioCurveball> _availableCurveballs = [
    ScenarioCurveball.none,
    ScenarioCurveball.wrongOrder,
    ScenarioCurveball.wrongReceipt,
  ];
  ScenarioCurveball _currentCurveball =
      ScenarioCurveball.longWait; //TODO: change back
  final List<String> _servedItems = [];

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

  final List<ScenarioStep> _globalSearchSteps = [
    ScenarioStep.drinksOffer, //TODO: add 'no drink' as an option
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
    _currentCurveball = ScenarioCurveball.longWait;
    //     _availableCurveballs[Random().nextInt(_availableCurveballs.length)];
    // print("⚾ INITIAL CURVEBALL: ${_currentCurveball.name}"); //TODO: change back

    _currentPrompt = await _promptService.fetchPrompt(_currentStep);
    _currentCharacter = _currentPrompt!.imageSpeakingUrl;
    _currentAudio = _currentPrompt!.audioUrl;

    dashboardManager.addSkillPracticed(_currentPrompt!.skillPracticedId);

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
    await _stopRecordingState();

    final transcript = _transcription.trim();
    _processDashboardMetrics(transcript);

    if (transcript.isEmpty) {
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

    _advanceScenario(intents, config);
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
    await _handlePromptOverride(config);
  }

  // --- Cleaned up Reusable Sequence ---
  Future<void> _executeCorrectionSequence(ImageConfiguration config) async {
    _currentCurveball = ScenarioCurveball.longWait; //TODO: change back
    _servedItems.clear();
    _servedItems.addAll(_orderItems);

    // 1. Apologize
    await _handleScenarioStepChange(ScenarioStep.wrongOrderApology, config);
    await updateFoodVisuals(_servedItems, config);

    // DELAY: 5 Seconds before serving the actual food
    await Future.delayed(const Duration(seconds: 5));

    // 2. Resolve (Show food and announce)
    await _handleScenarioStepChange(ScenarioStep.wrongOrderResolved, config);

    // DELAY: 5 Seconds before asking "how is everything"
    await Future.delayed(const Duration(seconds: 5));

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
      dashboardManager.incrementNumUnclearResponses();
      await _triggerFallback(
        "I'm not sure I understood. Could you try saying that another way?",
        config,
      );
      return null;
    }
    return classification?.intents ?? [];
  }

  Future<void> updateFoodVisuals(
    List<String> items,
    ImageConfiguration config,
  ) async {
    _appetizerUrl = null;
    _entreeUrl = null;

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
    ImageConfiguration config,
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

    bool orderedNewItems = false;
    for (String intent in intents) {
      if (intent.startsWith('order_') || intent.startsWith('side_')) {
        if (!_orderItems.contains(intent)) {
          _orderItems.add(intent);
          orderedNewItems = true;
        }
      }
    }

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
          _promptOverride = "My personal favourite is the ribeye steak.";
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
          _servedItems.clear();
          _servedItems.addAll(_orderItems);

          if (_currentCurveball == ScenarioCurveball.wrongOrder) {
            final allEntrees = ['order_pasta', 'order_chicken', 'order_steak'];
            final allApps = ['order_bruschetta', 'order_soup'];

            final orderedEntree = _servedItems.cast<String?>().firstWhere(
              (item) => allEntrees.contains(item),
              orElse: () => null,
            );

            if (orderedEntree != null) {
              final wrongEntrees = allEntrees
                  .where((item) => item != orderedEntree)
                  .toList();
              final wrongEntree =
                  wrongEntrees[Random().nextInt(wrongEntrees.length)];
              _servedItems.remove(orderedEntree);
              _servedItems.add(wrongEntree);
              print(
                "⚾ CURVEBALL APPLIED: Swapped $orderedEntree for $wrongEntree",
              );
            } else {
              final orderedApp = _servedItems.cast<String?>().firstWhere(
                (item) => allApps.contains(item),
                orElse: () => null,
              );

              if (orderedApp != null) {
                final wrongApps = allApps
                    .where((item) => item != orderedApp)
                    .toList();
                final wrongApp = wrongApps[Random().nextInt(wrongApps.length)];
                _servedItems.remove(orderedApp);
                _servedItems.add(wrongApp);
                print("⚾ CURVEBALL APPLIED: Swapped $orderedApp for $wrongApp");
              } else {
                _servedItems.add(
                  allEntrees[Random().nextInt(allEntrees.length)],
                );
              }
            }
          }

          if (_currentCurveball == ScenarioCurveball.longWait) {
            _currentStep = ScenarioStep.beBackShortly;
          } else if (_servedItems.contains('order_bruschetta')) {
            _currentStep = ScenarioStep.hereBruschetta;
          } else if (_servedItems.contains('order_soup')) {
            _currentStep = ScenarioStep.hereSoup;
          } else if (_servedItems.contains('order_pasta')) {
            _currentStep = ScenarioStep.herePasta;
          } else if (_servedItems.contains('order_chicken')) {
            _currentStep = ScenarioStep.hereChicken;
          } else if (_servedItems.contains('order_steak')) {
            _currentStep = ScenarioStep.hereSteak;
          } else {
            _currentStep = ScenarioStep.howIsEverything;
          }

          await updateFoodVisuals(_servedItems, config);
          await _handleScenarioStepChange(_currentStep, config);
        } else if (intents.contains('is_that_all_no')) {
          _currentStep = ScenarioStep.appetizers;
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;

      case ScenarioStep.beBackShortly:
        _showWaitTimer = true;
        _simulatedWaitMinutes = 0;
        notifyListeners();

        for (int i = 1; i <= 45; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          _simulatedWaitMinutes = i;
          notifyListeners();
        }

        _showWaitTimer = false;
        _showSystemMessage = true;
        _showRaiseHandButton = true;
        notifyListeners();

        break;

      case ScenarioStep.howHelp:
        _showRaiseHandButton = false;
        _currentStep = ScenarioStep.checkOrder;
        await _handleScenarioStepChange(_currentStep, config);
        notifyListeners();
        break;

      case ScenarioStep.checkOrder:
        // Clear the curveball since the user successfully navigated the long wait
        _currentCurveball = ScenarioCurveball.none;

        // Bring out the correct food based on what they ordered
        if (_servedItems.contains('order_bruschetta')) {
          _currentStep = ScenarioStep.hereBruschetta;
        } else if (_servedItems.contains('order_soup')) {
          _currentStep = ScenarioStep.hereSoup;
        } else if (_servedItems.contains('order_pasta')) {
          _currentStep = ScenarioStep.herePasta;
        } else if (_servedItems.contains('order_chicken')) {
          _currentStep = ScenarioStep.hereChicken;
        } else if (_servedItems.contains('order_steak')) {
          _currentStep = ScenarioStep.hereSteak;
        } else {
          // Fallback just in case nothing matches
          _currentStep = ScenarioStep.howIsEverything;
        }

        // Trigger the AI prompt and update the UI
        await _handleScenarioStepChange(_currentStep, config);
        notifyListeners();
        break;
      case ScenarioStep.wrongOrderApology:
      case ScenarioStep.wrongOrderResolved:
        break;
      case ScenarioStep.wrongOrderNudge:
        bool saidNo = intents.any((i) => ['nudge_no'].contains(i));

        if (saidNo) {
          print("✅ Curveball successfully navigated (Via Nudge)!");
          await _executeCorrectionSequence(config);
        } else {
          print("❌ Curveball Failed: User accepted wrong food after nudge.");
          _currentCurveball = ScenarioCurveball.none;
          _currentStep = ScenarioStep.howIsEverything;
          await _handleScenarioStepChange(_currentStep, config);
        }
        break;

      case ScenarioStep.hereBruschetta:
      case ScenarioStep.hereSoup:
        if (_servedItems.contains('order_pasta')) {
          _currentStep = ScenarioStep.herePasta;
        } else if (_servedItems.contains('order_chicken')) {
          _currentStep = ScenarioStep.hereChicken;
        } else if (_servedItems.contains('order_steak')) {
          _currentStep = ScenarioStep.hereSteak;
        } else {
          _currentStep = ScenarioStep.howIsEverything;
        }
        await precacheFood(_appetizerUrl!, config);
        await _handleScenarioStepChange(_currentStep, config);
        break;

      case ScenarioStep.herePasta:
      case ScenarioStep.hereChicken:
      case ScenarioStep.hereSteak:
        await precacheFood(entreeUrl!, config);
        _currentStep = ScenarioStep.howIsEverything;
        await _handleScenarioStepChange(_currentStep, config);
        break;

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
          _currentStep = ScenarioStep.checkReceipt;

          if (_currentCurveball == ScenarioCurveball.wrongReceipt) {
            _showStaticReceiptSheet = true;
          } else {
            _showReceiptSheet = true;
          }

          await _handleScenarioStepChange(_currentStep, config);
          notifyListeners();
        } else if (intents.contains('ready_for_bill_no')) {
          _promptOverride =
              "No problem, call me over when you're ready by saying 'I'm ready for the bill'";
          notifyListeners();
          await _handlePromptOverride(config);
        }
        break;

      case ScenarioStep.checkReceipt:
        if (intents.contains('wrong_receipt')) {
          _currentStep = ScenarioStep.resolveReceipt;
          _showReceiptSheet = true;
        } else {
          //TODO: increment some curveballsMissed stat
          _showReceiptSheet = false;
          _currentStep = ScenarioStep.paymentMethod;
        }

        _showStaticReceiptSheet = false;
        await _handleScenarioStepChange(_currentStep, config);
        notifyListeners();

        break;

      case ScenarioStep.resolveReceipt:
        _showReceiptSheet = false;
        _showStaticReceiptSheet = false;

        _currentStep = ScenarioStep.paymentMethod;
        await _handleScenarioStepChange(_currentStep, config);
        notifyListeners();
        break;
      case ScenarioStep.paymentMethod:
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

    _currentStep = ScenarioStep.isThatAll;
    _isScenarioComplete = false;
    _showReceiptSheet = false;
    _showStaticReceiptSheet = false;
    _showRaiseHandButton = false;

    _orderItems.clear();
    _servedItems.clear();

    _currentCurveball = ScenarioCurveball.longWait;
    // _availableCurveballs[Random().nextInt(_availableCurveballs.length)]; //TODO: change back

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
      print("Playing from local cache: $filePath");
      await _overridePlayer.setFilePath(filePath);
    } else {
      print("Fetching from ElevenLabs API...");
      Uint8List audioBytes = await _elevenLabsService.fetchAudio(text);
      await file.writeAsBytes(audioBytes);
      await _overridePlayer.setFilePath(filePath);
    }

    await _overridePlayer.play();
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
    _subscription?.cancel();
    hintManager.dispose();
    _audioPlayer.dispose();
    _overridePlayer.dispose();
    super.dispose();
  }
}
