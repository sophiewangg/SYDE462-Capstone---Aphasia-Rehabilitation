import 'dart:convert';
import 'package:aphasia_rehab_fe/models/cue_model.dart';
import 'package:aphasia_rehab_fe/models/simplified_prompt_model.dart';
import 'package:http/http.dart' as http;

class CueService {
  final String backendUrl = "http://localhost:8000/";

  Future<Cue?> getCues(String transcription, String goal) async {
    try {
      final response = await http.post(
        Uri.parse("${backendUrl}generate_cues/"),
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

  Future<SimplifiedPrompt?> getSimplifiedPrompt(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse("${backendUrl}simplify_prompt/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": prompt}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return SimplifiedPrompt.fromJson(jsonData);
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
