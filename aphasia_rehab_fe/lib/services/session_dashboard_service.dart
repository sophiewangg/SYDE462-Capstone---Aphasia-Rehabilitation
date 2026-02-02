import 'dart:convert';
import 'package:http/http.dart' as http;

class SessionDashboardService {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<List<String>> fetchSavedDetections() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/list_detections"));

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

  // Helper to get the full playable URL for a specific file
  String getAudioUrl(String filename) {
    return "$baseUrl/detections/$filename";
  }
}
