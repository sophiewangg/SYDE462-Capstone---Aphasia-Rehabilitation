import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ElevenLabsService {
  final String _apiKey = dotenv.get('ELEVEN_LABS_API_KEY');
  final String _voiceId = "21m00Tcm4TlvDq8ikWAM"; // Rachel voice
  Future<Uint8List> fetchAudio(String text) async {
    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId',
    );

    final response = await http.post(
      url,
      headers: {
        'Accept': 'audio/mpeg',
        'xi-api-key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "text": text,
        "model_id": "eleven_flash_v2_5", // <--- Updated from v1
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.5},
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception(
        'ElevenLabs API Error: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
