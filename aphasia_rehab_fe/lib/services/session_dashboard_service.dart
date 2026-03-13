import 'dart:convert';
import 'package:http/http.dart' as http;

class SessionDashboardService {
  // final String baseUrl = "http://127.0.0.1:8000";
  String baseUrl = "https://clotilde-squaretoed-fredrick.ngrok-free.dev";

  void clearDetections() async {
    try {
      await http.post(Uri.parse("$baseUrl/clear_detections"));
    } catch (e) {
      print("Error fetching detections: $e");
    }
  }

  Future<List<String>> fetchSavedDetections(String disfluencyType) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/list_detections?disfluency_type=$disfluencyType"),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception("Failed to load detections");
      }
    } catch (e) {
      print("Error fetching detections: $e");
      return [];
    }
  }

  Future<String> getSkillName(String skillId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_skill_name?skill_id=$skillId"),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['skill_name'] ?? "Unknown Skill";
      } else {
        print("Error fetching skill name: ${response.statusCode}");
        return "Unknown Skill";
      }
    } catch (e) {
      print("Error fetching skill name: $e");
      return "Unknown Skill";
    }
  }

  // Helper to get the full playable URL for a specific file
  String getAudioUrl(String filename, disfluency_type) {
    return "$baseUrl/detections/$disfluency_type/$filename";
  }
}
