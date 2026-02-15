import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/cue_model.dart';
import '../../services/transcription_service.dart';
import '../../services/cue_service.dart';
import '../../services/game_service.dart';
import 'widgets/microphone_button.dart';
import 'widgets/cue_modal.dart';
import 'widgets/transcription_display.dart';
import 'widgets/npc_bubble.dart';
import 'widgets/dialogue_display.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({super.key, required this.title});
  final String title;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  // Services
  final TranscriptionService _transcriptionService = TranscriptionService();
  final CueService _cueService = CueService();
  final GameService _gameService =
      GameService(); // <--- [NEW] Initialize GameService

  late StreamSubscription<TranscriptionResult> _subscription;

  // --- STATE VARIABLES ---
  String _currentTranscript = "";
  // Default text for the start of the game
  String _npcText = "Hi! Do you have a reservation?";
  // Holds cues if the user fails (null = hidden)
  Map<String, dynamic>? _currentCues;
  String _goal = "Ask for a utensil.";

  @override
  void initState() {
    super.initState();
    _requestMicPermission();

    // Listen to the stream
    _subscription = _transcriptionService.transcriptionStream.listen((result) {
      setState(() {
        _currentTranscript = result.text;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _transcriptionService.dispose();
    super.dispose();
  }

  Future<void> _requestMicPermission() async {
    await Permission.microphone.request();
  }

  // --- MAIN GAME LOGIC ---
  void _nextDialogueEvent(bool isRecording) async {
    // Only act when the user STOPS recording
    if (!isRecording) {
      if (_currentTranscript.isEmpty) return;

      print("📤 Sending to backend: $_currentTranscript");

      try {
        // 1. Send the audio text to your Python Backend
        final result = await _gameService.sendTurn(
          "user_123",
          _currentTranscript,
        );

        // 2. Update the UI based on the response
        setState(() {
          if (result['status'] == 'success') {
            _npcText = result['npc_text'] ?? _npcText;
            _currentCues = null;
          } else if (result['status'] == 'retry') {
            _npcText = result['feedback'] ?? _npcText;
            _currentCues = result['cues'];
          } else if (result['status'] == 'error') {
            _npcText = result['message'] ?? 'Something went wrong.';
            _currentCues = null;
          }
        });
      } catch (e) {
        print("Error connecting to game engine: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
      }
    }
  }

  // (Optional) Manual hint button logic - keeps your existing modal functionality
  void _handleHintPressed() {
    final cueFuture = _cueService.getCues(_currentTranscript, _goal);
    _showModal(cueFuture);
  }

  void _showModal(Future<Cue?> fetchedCue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CueModal(
          cueFuture: fetchedCue,
          transcriptionService: _transcriptionService,
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
      body: SafeArea(
        child: Column(
          children: [
            NpcBubble(text: _npcText),

            DialogueDisplay(text: _npcText),

            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TranscriptionDisplay(
                  stream: _transcriptionService.transcriptionStream,
                ),
              ),
            ),

            const SizedBox(height: 20),
            MicrophoneButton(
              service: _transcriptionService,
              onToggle: _nextDialogueEvent,
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: TextButton.icon(
                onPressed: _handleHintPressed,
                icon: const Icon(Icons.help_outline),
                label: const Text('Manual Hint'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
