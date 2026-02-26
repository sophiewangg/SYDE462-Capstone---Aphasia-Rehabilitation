import 'dart:convert';

import 'package:http/http.dart' as http;

class UtteranceClassification {
  final bool match;
  final String? intent;
  final Map<String, dynamic>? metadata;
  final double? distance;
  final String? text;

  UtteranceClassification({
    required this.match,
    this.intent,
    this.metadata,
    this.distance,
    this.text,
  });

  factory UtteranceClassification.fromJson(Map<String, dynamic> json) {
    return UtteranceClassification(
      match: json['match'] as bool? ?? false,
      intent: json['intent'] as String?,
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
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_classifyUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"transcription": transcription}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        // ignore: avoid_print
        print("🔎 classify_utterance response: $jsonData");
        return UtteranceClassification.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
