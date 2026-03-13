import 'dart:convert';
import 'package:http/http.dart' as http;

class SessionDashboardService {
  // final String baseUrl = "http://127.0.0.1:8000";
  String baseUrl = "https://clotilde-squaretoed-fredrick.ngrok-free.dev";

  void clearDetections() async {
    try {
      await http.post(Uri.parse("$baseUrl/clear_detections"));
    } catch (e) {
      print("Error clearing detections: $e");
    }
  }

  Future<int?> clearDetection(String filename, String disfluencyType) async {
    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/clear_detection?filename=$filename&disfluency_type=$disfluencyType",
        ),
      );

      return response.statusCode;
    } catch (e) {
      print("Error clearing detection: $e");
      return null;
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

  Future<String?> startImprovementTask(
    String prompt,
    String transcription,
  ) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/improve_response?prompt=$prompt&response=$transcription",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['task_id'];
    }
    return null;
  }

  Future<Map<String, dynamic>> checkTaskStatus(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/task_status/$taskId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to check task status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error checking Celery task status: $e");
      return {"status": "ERROR", "message": e.toString()};
    }
  }
}
