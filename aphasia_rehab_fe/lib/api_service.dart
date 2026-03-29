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

class OrderCorrectionResult {
  final bool isCorrected;
  final bool acceptedWrongFood;
  final bool mentionedCorrectItem;
  final bool rejectedWrongItem;
  final String? text;

  OrderCorrectionResult({
    required this.isCorrected,
    this.acceptedWrongFood = false,
    this.mentionedCorrectItem = false,
    this.rejectedWrongItem = false,
    this.text,
  });

  factory OrderCorrectionResult.fromJson(Map<String, dynamic> json) {
    return OrderCorrectionResult(
      isCorrected: json['is_corrected'] ?? false,
      acceptedWrongFood: json['accepted_wrong_food'] ?? false,
      mentionedCorrectItem: json['mentioned_correct_item'] ?? false,
      rejectedWrongItem: json['rejected_wrong_item'] ?? false,
      text: json['text'],
    );
  }
}

class ScenarioApiService {
  final String _classifyUrl = "http://localhost:8000/classify_utterance/";
  final String _verifyCorrectionUrl =
      "http://localhost:8000/verify_order_correction/";
  final String _llmFallbackUrl = "http://localhost:8000/llm_fallback/";

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

  Future<OrderCorrectionResult?> verifyOrderCorrection(
    String transcription,
    List<String> orderedItems,
    List<String> servedItems,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_verifyCorrectionUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "transcription": transcription,
          "ordered_items": orderedItems,
          "served_items": servedItems,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        print("🔎 verify_order_correction response: $jsonData");
        return OrderCorrectionResult.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      print("❌ Error in verifyOrderCorrection: $e");
      return null;
    }
  }

  Future<List<String>?> llmFallback(
    String transcription,
    String currentStep,
    String currentPrompt,
  ) async {
    try {
      print(transcription);
      final response = await http.post(
        Uri.parse(_llmFallbackUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "transcription": transcription,
          "current_step": currentStep,
          "current_prompt": currentPrompt,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        print("llm fallback response: $jsonData");

        final List<dynamic>? rawIntents = jsonData['intents'];

        if (rawIntents == null) return null;

        return rawIntents.map((item) => item.toString()).toList();
      } else {
        return null;
      }
    } catch (e) {
      print("Error in LLM Fallback: $e");
      return null;
    }
  }
}
