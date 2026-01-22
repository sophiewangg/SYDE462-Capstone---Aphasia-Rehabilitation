import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/cue_model.dart';
import '../../services/transcription_service.dart';
import '../../services/cue_service.dart';
import 'widgets/microphone_button.dart';
import 'widgets/cue_modal.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({super.key, required this.title});
  final String title;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final TranscriptionService _transcriptionService = TranscriptionService();
  final CueService _cueService = CueService();
  String _transcription = "";
  String _goal = "Ask for a utensil.";

  @override
  void initState() {
    super.initState();
    _requestMicPermission();
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    print(status); // granted / denied / permanentlyDenied
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
        // Pass the service and the current transcription string
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
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Expanded(
              child: StreamBuilder<String>(
                stream: _transcriptionService.transcriptionStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _transcription = snapshot.data!;
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _transcription.isNotEmpty
                          ? _transcription
                          : "Press start to transcribe...",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: MicrophoneButton(service: _transcriptionService),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: ElevatedButton(
                onPressed: () {
                  // 1. Kick off the request (don't 'await' it here)
                  final cueFuture = _cueService.getCues(_transcription, _goal);

                  // 2. Open the modal immediately
                  _showModal(cueFuture);
                },
                child: const Text('I need a hint!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
