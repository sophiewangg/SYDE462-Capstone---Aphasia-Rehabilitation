import 'package:flutter/material.dart';
import 'package:aphasia_rehab_fe/services/session_dashboard_service.dart';
import 'package:audioplayers/audioplayers.dart';

class SessionDashboardPage extends StatefulWidget {
  const SessionDashboardPage({super.key});

  @override
  State<SessionDashboardPage> createState() => _SessionDashboardPageState();
}

class _SessionDashboardPageState extends State<SessionDashboardPage> {
  final SessionDashboardService _dashboardService = SessionDashboardService();
  late Future<List<String>> _detectionsFuture;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _detectionsFuture = _dashboardService.fetchSavedDetections();
  }

  // Method to manually refresh the list
  void _refreshDetections() {
    setState(() {
      _detectionsFuture = _dashboardService.fetchSavedDetections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Session Detections"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDetections,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Detected Disfluencies",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("The following clips were flagged by the AI:"),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _detectionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No detections found yet."),
                    );
                  }

                  final files = snapshot.data!;

                  return ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final filename = files[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: const Icon(
                            Icons.audiotrack,
                            color: Colors.blue,
                          ),
                          title: Text(filename),
                          subtitle: const Text("Tap to play detection"),
                          trailing: const Icon(Icons.play_arrow),
                          onTap: () async {
                            // 2. Show the snackbar so the user knows something is happening
                            _showPlaybackSnackBar(filename);

                            // 3. Get the full URL (e.g., http://127.0.0.1:8000/detections/file.wav)
                            String url = _dashboardService.getAudioUrl(
                              filename,
                            );

                            try {
                              // 4. Actually trigger the audio engine
                              await _audioPlayer.play(UrlSource(url));
                            } catch (e) {
                              print("Error playing audio: $e");
                              // Optional: Show an error snackbar if it fails
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaybackSnackBar(String filename) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Preparing to play: $filename")));
  }
}
