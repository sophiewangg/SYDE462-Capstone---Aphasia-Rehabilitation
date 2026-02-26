import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../services/transcription_service.dart';
import 'scenario_complete_page.dart';
import 'widgets/character.dart';
import 'widgets/hint_button.dart';
import 'widgets/mic_button_idle.dart';
import 'widgets/mic_button_processing.dart';
import 'widgets/mic_button_speaking.dart';
import 'widgets/select_hint.dart';
import 'widgets/settings_button.dart';
import 'widgets/speech_bubble.dart';

class ScenarioSim extends StatefulWidget {
  const ScenarioSim({super.key});

  @override
  State<ScenarioSim> createState() => _ScenarioSimState();
}

enum PromptState { userSpeaking, characterSpeaking, processing }

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

class _ScenarioSimState extends State<ScenarioSim> {
  final _player = AudioPlayer();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final ScenarioApiService _scenarioApiService = ScenarioApiService();

  StreamSubscription<TranscriptionResult>? _transcriptionSub;
  String _latestTranscript = "";
  bool _hintButtonPressed = false;
  final List<String> _orderItems = [];

  final Map<ScenarioStep, ScenarioPrompt> _prompts = {
    ScenarioStep.drinksOffer: ScenarioPrompt(
      id: 'drinks_offer',
      text: "Here's the menu. Can I get you started with any drinks?",
      audioAsset: null,
    ),
    ScenarioStep.waterType: ScenarioPrompt(
      id: 'water_type',
      text: "Still or sparkling?",
      audioAsset: null,
    ),
    ScenarioStep.iceQuestion: ScenarioPrompt(
      id: 'ice_question',
      text: "Would you like ice with it?",
      audioAsset: null,
    ),
    ScenarioStep.readyToOrder: ScenarioPrompt(
      id: 'ready_to_order',
      text: "Are you ready to order?",
      audioAsset: null,
    ),
    ScenarioStep.appetizers: ScenarioPrompt(
      id: 'appetizers',
      text: "Any appetizers to get you started?",
      audioAsset: null,
    ),
    ScenarioStep.steakDoneness: ScenarioPrompt(
      id: 'steak_doneness',
      text: "How would you like your steak?",
      audioAsset: null,
    ),
    ScenarioStep.sideChoice: ScenarioPrompt(
      id: 'side_choice',
      text: "Would you like salad or fries as your side?",
      audioAsset: null,
    ),
    ScenarioStep.isThatAll: ScenarioPrompt(
      id: 'is_that_all',
      text: "Is that all for you?",
      audioAsset: null,
    ),
    ScenarioStep.allergies: ScenarioPrompt(
      id: 'allergies',
      text: "Do you have any allergies?",
      audioAsset: null,
    ),
  };

  ScenarioStep _currentStep = ScenarioStep.drinksOffer;
  PromptState _currentPromptState = PromptState.characterSpeaking;
  String? _systemMessage;
  String? _promptPrefix;
  String? _promptOverride;

  bool _isRecording = false;

  String _currentPromptText() {
    final base = _prompts[_currentStep]?.text ?? "";
    if (_promptOverride != null) return _promptOverride!;
    if (_promptPrefix != null) return "${_promptPrefix!}$base";
    return base;
  }

  void toggleHintButton() {
    setState(() {
      _hintButtonPressed = !_hintButtonPressed;
    });
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    _transcriptionService.startStreaming();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    await _transcriptionService.stopStreaming();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _playPromptAndListen() async {
    final prompt = _prompts[_currentStep];
    if (prompt == null) return;

    setState(() {
      _currentPromptState = PromptState.characterSpeaking;
    });

    if (prompt.audioAsset != null) {
      await _player.play(AssetSource(prompt.audioAsset!));
      await _player.onPlayerComplete.first;
    }

    if (!mounted) return;

    setState(() {
      _currentPromptState = PromptState.userSpeaking;
    });

    await _startRecording();
  }

  Future<void> _handleUserTurnCompleted() async {
    if (_currentPromptState != PromptState.userSpeaking) return;

    await _stopRecording();

    setState(() {
      _currentPromptState = PromptState.processing;
    });

    final transcript = _latestTranscript.trim();
    if (transcript.isEmpty) {
      setState(() {
        _promptPrefix = "I didn't quite hear that. Could you try again? ";
        _currentPromptState = PromptState.userSpeaking;
      });
      await _startRecording();
      return;
    }

    final classification = await _scenarioApiService.classifyUtterance(
      transcript,
    );

    if (!mounted) return;

    if (classification == null || !classification.match) {
      setState(() {
        _systemMessage =
            "I'm not sure I understood. Could you try saying that another way?";
        _currentPromptState = PromptState.userSpeaking;
      });
      await _startRecording();
      return;
    }

    // If we're on the final step, treat any valid answer as completion.
    if (_currentStep == ScenarioStep.allergies) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ScenarioCompletePage()),
      );
      return;
    }

    _advanceScenario(classification.intent);

    if (!mounted) return;

    await _playPromptAndListen();
  }

  void _advanceScenario(String? intent) {
    switch (_currentStep) {
      case ScenarioStep.drinksOffer:
        if (intent == 'beverage_water') {
          _currentStep = ScenarioStep.waterType;
        } else if (intent == 'water_still' || intent == 'water_sparkling') {
          // User already specified the water type; skip ahead.
          _currentStep = ScenarioStep.iceQuestion;
        } else if (intent == 'beverage_other') {
          _currentStep = ScenarioStep.iceQuestion;
        }
        break;
      case ScenarioStep.waterType:
        if (intent == 'water_still' || intent == 'water_sparkling') {
          _currentStep = ScenarioStep.iceQuestion;
        }
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
          _systemMessage = null;
        }
        break;
      case ScenarioStep.appetizers:
        if (intent == 'ask_specials' || intent == 'ask_soup') {
          _systemMessage =
              "Today's soup is a creamy roasted garlic, miso and cauliflower soup.";
        } else if (intent == 'ask_recommendations') {
          _systemMessage = "My personal favourite entree is the lobster pasta.";
        } else if (intent == 'order_steak') {
          _currentStep = ScenarioStep.steakDoneness;
        } else if (intent == 'order_chicken') {
          _orderItems.add("chicken entree");
          _currentStep = ScenarioStep.isThatAll;
        } else if (intent == 'order_pasta') {
          _orderItems.add("pasta entree");
          _currentStep = ScenarioStep.isThatAll;
        }
        break;
      case ScenarioStep.steakDoneness:
        if (intent == 'steak_doneness') {
          _currentStep = ScenarioStep.sideChoice;
        }
        break;
      case ScenarioStep.sideChoice:
        if (intent == 'side_salad') {
          _orderItems.add("steak with salad");
          _currentStep = ScenarioStep.isThatAll;
        } else if (intent == 'side_fries') {
          _orderItems.add("steak with fries");
          _currentStep = ScenarioStep.isThatAll;
        }
        break;
      case ScenarioStep.isThatAll:
        if (intent == 'is_that_all_yes') {
          _currentStep = ScenarioStep.allergies;
        } else if (intent == 'is_that_all_no') {
          _currentStep = ScenarioStep.appetizers;
        }
        break;
      case ScenarioStep.allergies:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _transcriptionSub = _transcriptionService.transcriptionStream.listen((
      result,
    ) {
      _latestTranscript = result.text;
      if (result.isEndOfTurn &&
          _currentPromptState == PromptState.userSpeaking) {
        _handleUserTurnCompleted();
      }
    });

    _playPromptAndListen();
  }

  @override
  void dispose() {
    _transcriptionSub?.cancel();
    _transcriptionService.dispose();
    _player.dispose();
    super.dispose();
  }

  Widget _buildMicButton() {
    switch (_currentPromptState) {
      case PromptState.characterSpeaking:
        return MicButtonIdle();
      case PromptState.userSpeaking:
        return MicButtonSpeaking(onStopSpeaking: _handleUserTurnCompleted);
      case PromptState.processing:
        return MicButtonProcessing();
      default:
        return MicButtonIdle();
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  "assets/backgrounds/restaurant_background.png",
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () {
                _stopRecording();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),

          Positioned(bottom: 30, right: 0, child: Character()),
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/table_image.png',
              height: 250,
              fit: BoxFit.contain,
            ),
          ),

          Positioned(top: 75, right: 20, child: SettingsButton()),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: SizedBox(
                width: 350,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10.0,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpeechBubble(prompt: _currentPromptText()),
                    SizedBox(
                      height: 46,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: (_systemMessage == null)
                            ? const SizedBox.shrink()
                            : Text(
                                _systemMessage!,
                                key: const ValueKey("system_message"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                ),
                                softWrap: true,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 150,
                      child: _hintButtonPressed
                          ? SelectHint()
                          : const SizedBox.shrink(),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 20.0,
                      children: [
                        HintButton(
                          toggleHintButton: toggleHintButton,
                          hintButtonPressed: _hintButtonPressed,
                        ),
                        _buildMicButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
