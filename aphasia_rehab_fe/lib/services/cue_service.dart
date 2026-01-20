import 'dart:convert';
import 'package:aphasia_rehab_fe/models/cue_model.dart';
import 'package:http/http.dart' as http;

class CueService {
  final String backendUrl = "http://localhost:8000/generate_cues/";

  Future<Cue?> getCues(String transcription, String goal) async {
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"transcription": transcription, "goal": goal}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return Cue.fromJson(jsonData);
      } else {
        print("Server error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Failed to generate cues.");
      return null;
    }
  }
}
