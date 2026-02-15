import 'dart:convert';
import 'package:http/http.dart' as http;

class GameService {
  final String backendUrl = "http://localhost:8000/game/speak";

  /// Sends the user's transcript to the game engine and returns the result.
  /// Returns a map with: status ('success' | 'retry' | 'error'),
  /// and on success: npc_text; on retry: feedback, cues; on error: message.
  Future<Map<String, dynamic>> sendTurn(
    String userId,
    String transcript,
  ) async {
    try {
      final uri = Uri.parse(
        backendUrl,
      ).replace(queryParameters: {'user_id': userId});
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": transcript}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        return {
          "status": "error",
          "message": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }
}
