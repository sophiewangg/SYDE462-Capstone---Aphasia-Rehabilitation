import 'package:aphasia_rehab_fe/services/eleven_labs_service.dart';
import 'package:aphasia_rehab_fe/services/session_dashboard_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class DashboardManager extends ChangeNotifier {
  final SessionDashboardService _dashboardService = SessionDashboardService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ElevenLabsService _elevenLabsService = ElevenLabsService();

  // State variables
  // Hints Used
  int _numHintsUsed = 0;
  int _numHintsSuccess = 0;
  final List<String> _hintsGiven = [];

  // Response Clarity
  int _numPromptsGiven = 1;
  int _numUnclearResponses = 0;

  // Skills Practiced
  final Map<String, int> _skillsPracticed = {};

  // getters
  int get numHintsUsed => _numHintsUsed;
  int get numHintsSuccess => _numHintsSuccess;
  List<String> get hintsGiven => _hintsGiven;
  int get numPromptsGiven => _numPromptsGiven;
  int get numUnclearResponses => _numUnclearResponses;
  Map<String, int> get skillsPracticed => _skillsPracticed;

  void cueComplete(int numCues, String hintGiven) {
    print(hintGiven);
    _numHintsUsed += 1;
    if (numCues <= 2) {
      _numHintsSuccess += 1;
    }
    // get the cue
    _hintsGiven.add(hintGiven);
    notifyListeners();
  }

  void incrementNumUnclearResponses() {
    _numUnclearResponses += 1;
  }

  void incrementNumPromptsGiven() {
    _numPromptsGiven += 1;
  }

  void addSkillPracticed(String skill_id) {
    if (!_skillsPracticed.containsKey(skill_id)) {
      _skillsPracticed[skill_id] = 0;
    }
    notifyListeners();
  }

  Future<String> getSkillName(String skillId) async {
    return await _dashboardService.getSkillName(skillId);
  }

  Future<void> playElevenLabsAudio(String text, String promptId) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/audio_$promptId.mp3';
    final file = File(filePath);

    if (await file.exists()) {
      // 1. Play from Cache
      print("Playing from local cache: $filePath");
      await _audioPlayer.setFilePath(filePath);
    } else {
      // 2. Fetch from ElevenLabs API
      print("Fetching from ElevenLabs API...");
      Uint8List audioBytes = await _elevenLabsService.fetchAudio(text);

      // 3. Save to Cache
      await file.writeAsBytes(audioBytes);

      await _audioPlayer.setFilePath(filePath);
    }

    await _audioPlayer.play();
  }
}
