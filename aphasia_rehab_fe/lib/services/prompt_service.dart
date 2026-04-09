import 'dart:convert';
import 'package:aphasia_rehab_fe/models/prompt_model.dart';
import 'package:aphasia_rehab_fe/models/scenario_step.dart';
import 'package:http/http.dart' as http;

class PromptService {
  // final String baseUrl = "http://127.0.0.1:8000";
  final String baseUrl = "https://clotilde-squaretoed-fredrick.ngrok-free.dev";

  Future<Prompt> fetchPrompt(ScenarioStep scenarioStep) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/next_prompt?scenario_step_description=${scenarioStep.dbValue}",
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Prompt.fromJson(json);
      } else {
        print("Error fetching next prompt: ${response.statusCode}");
        return Prompt(
          id: "",
          scenarioStepId: "",
          audioUrl: "",
          imageSpeakingUrl: "",
          imageListeningUrl: "",
          imageConfusedUrl: "",
          skillPracticedId: "",
          promptText: "",
        );
      }
    } catch (e) {
      print("Error fetching next prompt: $e");
      return Prompt(
        id: "",
        scenarioStepId: "",
        audioUrl: "",
        imageSpeakingUrl: "",
        imageListeningUrl: "",
        imageConfusedUrl: "",
        skillPracticedId: "",
        promptText: "",
      );
    }
  }

  Future<String> getSignedUrl(String url, String bucket) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/generate_signed_url?url=$url&bucket=$bucket"),
      );

      if (response.statusCode == 200) {
        // 1. Decode the body
        final data = jsonDecode(response.body);

        // 2. Check if it's a String (most likely based on your error)
        if (data is String) {
          return data;
        }
        // 3. Fallback: If it's a List, get the first item
        else if (data is List && data.isNotEmpty) {
          return data[0].toString();
        }

        return "";
      } else {
        throw Exception("Failed to load signed URL: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching signed URL: $e");
      return "";
    }
  }
}
