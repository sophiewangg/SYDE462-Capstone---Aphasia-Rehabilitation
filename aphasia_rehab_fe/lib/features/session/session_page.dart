import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/cue_model.dart';
import '../../services/transcription_service.dart';
import '../../services/cue_service.dart';
import 'widgets/cue_modal.dart';
import 'widgets/transcription_display.dart';
import 'widgets/mic_and_hint_button.dart';
import 'scenario_sim.dart';
import 'package:aphasia_rehab_fe/models/prompt_state.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({super.key, required this.title});
  final String title;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final TranscriptionService _transcriptionService = TranscriptionService();
  final CueService _cueService = CueService();

  late StreamSubscription<TranscriptionResult> _subscription;
  String _transcription = "";
  String _goal = "Ask for a utensil.";
  bool _isRecording = false;
  bool _hintButtonPressed = false;
  String? _likelyWord;
  List<String> prompts = [
    "Hello! How are you doing?",
    "Would you like something to drink?",
    "What would you like to order?",
    "Here is your food. Enjoy your meal!",
    "Can I get you anything else?",
    "Thank you! Have a great day!",
  ];
  int _currentPromptIndex = 0;
  final ValueNotifier<PromptState> _currentPromptState = ValueNotifier(
    PromptState.idle,
  );

  final ValueNotifier<PromptState> _currentPromptStateModal = ValueNotifier(
    PromptState.idle,
  );

  final ValueNotifier<bool> _cueCompleteNotifier = ValueNotifier(false);

  final ValueNotifier<String?> _cueResultStringNotifier = ValueNotifier(null);

  final ValueNotifier<int> _cueNumberNotifier = ValueNotifier(0);

  void updateCueNumber({bool reset = false}) {
    if (reset) {
      _cueNumberNotifier.value = 0;
    } else {
      _cueNumberNotifier.value = _cueNumberNotifier.value + 1;
    }
  }

  void resetCueComplete() {
    _cueCompleteNotifier.value = false;
  }

  void resetCueResultString() {
    _cueResultStringNotifier.value = null;
  }

  void toggleHintButton() {
    setState(() {
      _hintButtonPressed = !_hintButtonPressed;
    });
  }

  void updateCurrentPromptState() {
    if (_currentPromptState.value == PromptState.userSpeaking) {
      _currentPromptState.value = PromptState.processing;

      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _currentPromptIndex = (_currentPromptIndex + 1) % prompts.length;
          _currentPromptState.value =
              PromptState.idle; // This will now auto-update the modal!
        }
      });
    } else if (_currentPromptState.value == PromptState.idle) {
      _currentPromptState.value = PromptState.userSpeaking;
    }
  }

  void updateCurrentPromptStateModal() {
    if (_currentPromptStateModal.value == PromptState.userSpeaking) {
      _currentPromptStateModal.value = PromptState.processing;
      processSpeechFromCue(_likelyWord ?? "");
      // processSpeechFromCue();
    } else if (_currentPromptStateModal.value == PromptState.idle) {
      _currentPromptStateModal.value = PromptState.userSpeaking;
    }
  }

  // Update the function to accept the target word
  void processSpeechFromCue(String targetWord) async {
    print("Processing speech. Latest transcript: $_transcription");

    // Clean up the strings for a fair comparison
    String cleanTranscript = _transcription.toLowerCase().trim();
    String cleanTarget = targetWord.toLowerCase().trim();

    if (cleanTranscript.contains(cleanTarget)) {
      print("Success! Word detected.");
      // Just update the value. The ValueListenableBuilder in the modal hears this!
      _cueCompleteNotifier.value = true;
      _currentPromptStateModal.value = PromptState.idle;
      _cueResultStringNotifier.value =
          "Correct! The word is ${targetWord.toUpperCase()}";

      // TODO: If you want the modal to show a 'Success' checkmark,
      // you should use another ValueNotifier<bool> for _cueComplete.
    } else {
      print("Word not matched yet.");
      // Revert to idle so they can try again
      _cueResultStringNotifier.value = "Not quite. Here's another hint:";
      updateCueNumber();
      _currentPromptStateModal.value = PromptState.idle;
    }
  }

  @override
  void initState() {
    super.initState();
    _requestMicPermission();

    // Listen to the stream for logic purposes (updating _transcription for the Hint button)
    _subscription = _transcriptionService.transcriptionStream.listen((result) {
      setState(() {
        _transcription = result.text;
      });
      if (result.isEndOfTurn && _isRecording) {
        _stopRecording(); // Explicitly stop instead of toggling
        bool isModalOpen = ModalRoute.of(context)?.isCurrent == false;
        isModalOpen
            ? updateCurrentPromptStateModal()
            : updateCurrentPromptState(); // Update the prompt state when the turn ends
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _transcriptionService.dispose();
    super.dispose();
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    print(status); // granted / denied / permanentlyDenied
  }

  void _startRecording() {
    _transcriptionService.startStreaming();
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording() {
    _transcriptionService.stopStreaming();
    setState(() {
      _isRecording = false;
    });

    print("End of turn. Triggering next dialogue event.");
    // This can only get worked on when we actually have the structure of the dialogue events in the scenarios
    // When the dialogue event ends, this would trigger the mic to automatically turn on and listent for the user's response
  }

  void _handleMicToggle() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _handleHintPressed() async {
    // 1. Kick off the request (don't 'await' it here)
    final cueFuture = _cueService.getCues(_transcription, _goal);
    toggleHintButton();
    setState(() {
      _currentPromptState.value = PromptState.idle;
    });
    _stopRecording();
    // 2. Open the modal immediately

    _showModal(cueFuture);

    // Separately, wait for the future to finish to save the word locally
    final fetchedCue = await cueFuture;

    if (fetchedCue != null) {
      setState(() {
        _likelyWord = fetchedCue.likelyWord;
      });
    }
  }

  void _showModal(Future<Cue?> fetchedCue) {
    _cueCompleteNotifier.value = false;
    _currentPromptStateModal.value = PromptState.idle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (BuildContext context) {
        // AnimatedBuilder is the correct widget for Listenable.merge
        return AnimatedBuilder(
          animation: Listenable.merge([
            _currentPromptStateModal,
            _cueCompleteNotifier,
            _cueResultStringNotifier,
            _cueNumberNotifier,
          ]),
          builder: (context, _) {
            return CueModal(
              cueFuture: fetchedCue,
              startRecording: _startRecording,
              updateCurrentPromptState: updateCurrentPromptStateModal,
              currentPromptState: _currentPromptStateModal.value,
              cueComplete: _cueCompleteNotifier.value,
              cueResultString: _cueResultStringNotifier.value,
              cueNumber: _cueNumberNotifier.value,
              updateCueNumber: updateCueNumber,
              resetCueComplete: resetCueComplete,
              resetCueResultString: resetCueResultString,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Expanded(
              child: TranscriptionDisplay(
                stream: _transcriptionService.transcriptionStream,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScenarioSim()),
                );
              },
              child: const Text('Go to scenario'),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: ValueListenableBuilder<PromptState>(
                valueListenable: _currentPromptState,
                builder: (context, state, child) {
                  // 'state' here is the current value of _currentPromptState
                  return MicAndHintButton(
                    currentPrompt: "",
                    hintButtonPressed: _hintButtonPressed,
                    currentPromptState:
                        state, // Use the 'state' from the builder
                    updateCurrentPromptState: updateCurrentPromptState,
                    toggleHintButton: toggleHintButton,
                    onPressedMic: _handleMicToggle,
                    handleHintPressed: _handleHintPressed,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
