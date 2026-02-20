import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/cue_model.dart';
import '../../services/transcription_service.dart';
import '../../services/cue_service.dart';
import 'widgets/cue_modal.dart';
import 'widgets/transcription_display.dart';
import 'scenario_sim.dart';
import 'package:aphasia_rehab_fe/models/microphone_state.dart';

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
  final ValueNotifier<MicrophoneState> _currentMicrophoneState = ValueNotifier(
    MicrophoneState.idle,
  );

  final ValueNotifier<MicrophoneState> _currentMicrophoneStateModal =
      ValueNotifier(MicrophoneState.idle);

  final ValueNotifier<bool> _cueCompleteNotifier = ValueNotifier(false);

  final ValueNotifier<String?> _cueResultStringNotifier = ValueNotifier(null);

  final ValueNotifier<int> _cueNumberNotifier = ValueNotifier(0);

  bool _modalIsWordFinding = true;

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

  void updateCurrentMicrophoneState() {
    if (_currentMicrophoneState.value == MicrophoneState.userSpeaking) {
      _currentMicrophoneState.value = MicrophoneState.processing;

      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _currentPromptIndex = (_currentPromptIndex + 1) % prompts.length;
          _currentMicrophoneState.value =
              MicrophoneState.idle; // This will now auto-update the modal!
        }
      });
    } else if (_currentMicrophoneState.value == MicrophoneState.idle) {
      _currentMicrophoneState.value = MicrophoneState.userSpeaking;
    }
  }

  void updateCurrentMicrophoneStateModal() {
    if (_currentMicrophoneStateModal.value == MicrophoneState.userSpeaking) {
      _currentMicrophoneStateModal.value = MicrophoneState.processing;
      if (_modalIsWordFinding) {
        processSpeechWordFinding(_likelyWord ?? "");
      } else {
        processSpeechUnderstanding();
      }
    } else if (_currentMicrophoneStateModal.value == MicrophoneState.idle) {
      _currentMicrophoneStateModal.value = MicrophoneState.userSpeaking;
    }
  }

  void processSpeechWordFinding(String targetWord) async {
    print("Processing speech. Latest transcript: $_transcription");

    String cleanTranscript = _transcription.toLowerCase().trim();
    String cleanTarget = targetWord.toLowerCase().trim();

    if (cleanTranscript.contains(cleanTarget)) {
      print("Success! Word detected.");
      _cueCompleteNotifier.value = true;
      _currentMicrophoneStateModal.value = MicrophoneState.idle;
      _cueResultStringNotifier.value =
          "Correct! The word is ${targetWord.toUpperCase()}";
    } else {
      print("Word not matched yet.");
      // Revert to idle so they can try again
      _cueResultStringNotifier.value = "Not quite. Here's another hint:";
      updateCueNumber();
      _currentMicrophoneStateModal.value = MicrophoneState.idle;
    }
  }

  void processSpeechUnderstanding() {
    print("Sucess! User indicated they didn't understand.");
    _cueCompleteNotifier.value = true;
    _currentMicrophoneStateModal.value = MicrophoneState.idle;
    _cueResultStringNotifier.value = "Return to exercise.";
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
            ? updateCurrentMicrophoneStateModal()
            : updateCurrentMicrophoneState(); // Update the prompt state when the turn ends
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

  void _handleHintPressed(bool isWordFinding) async {
    setState(() {
      _modalIsWordFinding = isWordFinding;
      _hintButtonPressed = false;
    });

    if (isWordFinding) {
      // 1. Kick off the request (don't 'await' it here)
      final cueFuture = _cueService.getCues(_transcription, _goal);
      toggleHintButton();
      setState(() {
        _currentMicrophoneState.value = MicrophoneState.idle;
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
    } else {
      // 1. Create a Future that is already finished with null data
      final noCueFuture = Future<Cue?>.value(null);

      // 2. Open the modal immediately
      _showModal(noCueFuture);
    }
  }

  void _showModal(Future<Cue?> fetchedCue) {
    _cueCompleteNotifier.value = false;
    _currentMicrophoneStateModal.value = MicrophoneState.idle;

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
            _currentMicrophoneStateModal,
            _cueCompleteNotifier,
            _cueResultStringNotifier,
            _cueNumberNotifier,
          ]),
          builder: (context, _) {
            return CueModal(cueFuture: fetchedCue);
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
          ],
        ),
      ),
    );
  }
}
