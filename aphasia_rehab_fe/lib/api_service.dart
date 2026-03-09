import 'dart:convert';
import 'package:http/http.dart' as http;

class UtteranceClassification {
  final bool match;
  final List<String> intents;
  final Map<String, dynamic>? metadata;
  final double? distance;
  final String? text;

  UtteranceClassification({
    required this.match,
    this.intents = const [],
    this.metadata,
    this.distance,
    this.text,
  });

  factory UtteranceClassification.fromJson(Map<String, dynamic> json) {
    List<String> parsedIntents = [];

    // Safely parse and sanitize the intents list to prevent whitespace mismatch bugs
    if (json['intents'] != null && json['intents'] is List) {
      parsedIntents = (json['intents'] as List)
          .map((intent) => intent.toString().trim())
          .toList();
      print(parsedIntents);
    } else if (json['intent'] != null) {
      parsedIntents = [json['intent'].toString().trim()];
    }

    return UtteranceClassification(
      match: json['match'] as bool? ?? false,
      intents: parsedIntents,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      distance: (json['distance'] is num)
          ? (json['distance'] as num).toDouble()
          : null,
      text: json['text'] as String?,
    );
  }
}

class ScenarioApiService {
  final String _classifyUrl = "http://localhost:8000/classify_utterance/";

  Future<UtteranceClassification?> classifyUtterance(
    String transcription,
    String? currentStep, {
    bool globalSearch = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_classifyUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "transcription": transcription,
          "current_step": currentStep,
          "global_search": globalSearch,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        print("🔎 classify_utterance response: $jsonData");
        return UtteranceClassification.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      print("❌ Error in classifyUtterance: $e");
      return null;
    }
  }
}
